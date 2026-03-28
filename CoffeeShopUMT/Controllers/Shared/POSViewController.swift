import UIKit
import FirebaseFirestore

final class POSViewController: UIViewController {

    // MARK: - Data

    private var allMenuItems: [MenuItem] = []
    private var filteredMenuItems: [MenuItem] = []

    // Per-table orders: key = tableId, value = items for that table
    private var ordersByTableId: [String: [CartItem]] = [:]

    private var selectedTableOption: TableOption?
    private var selectedCategory: String?

    // Real-time orders — dùng để theo dõi trạng thái bàn
    private var activeOrders: [Order] = []
    private var ordersListener: ListenerRegistration?

    /// Đơn đang active (chưa thanh toán) của bàn hiện tại
    private var unpaidOrderForCurrentTable: Order? {
        guard let tableId = selectedTableOption?.id else { return nil }
        return activeOrders.first { $0.tableId == tableId && !$0.isPaid }
    }

    // Items for the currently selected table
    private var currentCartItems: [CartItem] {
        get { ordersByTableId[selectedTableOption?.id ?? ""] ?? [] }
        set {
            guard let id = selectedTableOption?.id else { return }
            ordersByTableId[id] = newValue.isEmpty ? nil : newValue
        }
    }

    private var categories: [String] {
        let distinct = Set(allMenuItems.map { $0.category }).sorted()
        return ["Tất cả"] + distinct
    }

    // MARK: - UI references

    private var tableButton: UIButton?
    private var searchBar: UISearchBar?
    private var categoryCollectionView: UICollectionView?
    private var productTableView: UITableView?
    private var orderButton: UIButton?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#221910")
        locateStoryboardViews()
        addProductTableView()
        fetchMenuItems()
        startListeningOrders()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchMenuItems()
    }

    deinit {
        ordersListener?.remove()
    }

    // MARK: - Locate storyboard elements

    private func locateStoryboardViews() {
        // Table button: plain style, title "Table"
        tableButton = view.findSubviews(of: UIButton.self).first {
            $0.configuration?.title == "Table" || $0.title(for: .normal) == "Table"
        }
        tableButton?.addTarget(self, action: #selector(didTapTable), for: .touchUpInside)

        // SearchBar
        searchBar = view.findSubviews(of: UISearchBar.self).first
        searchBar?.delegate = self

        // Category collection view: the UICollectionView present in storyboard
        categoryCollectionView = view.findSubviews(of: UICollectionView.self).first
        categoryCollectionView?.dataSource = self
        categoryCollectionView?.delegate = self
        categoryCollectionView?.backgroundColor = .clear

        // Order button: filled style, title "Đơn hàng"
        orderButton = view.findSubviews(of: UIButton.self).first {
            $0.configuration?.title == "Đơn hàng" || $0.title(for: .normal) == "Đơn hàng"
        }
        orderButton?.addTarget(self, action: #selector(didTapOrder), for: .touchUpInside)
    }

    // MARK: - Product table view (programmatic)

    private func addProductTableView() {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.1)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProductCell")
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        productTableView = tableView

        // Anchor after layout pass so frames are known, but we use the view hierarchy
        // We need categoryCollectionView and orderButton to be laid out first.
        view.layoutIfNeeded()

        guard let catCV = categoryCollectionView,
              let orderBtn = orderButton else {
            // Fallback: stretch to safe area
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 120),
                tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80)
            ])
            return
        }

        let containerView = orderBtn.superview ?? view!

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: catCV.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.topAnchor, constant: -8)
        ])
    }

    // MARK: - Orders listener

    private func startListeningOrders() {
        ordersListener = DatabaseService.shared.listenToOrders { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                if case .success(let orders) = result {
                    // Chỉ giữ đơn chưa thanh toán (pending hoặc ready)
                    self.activeOrders = orders.filter { !$0.isPaid }
                    self.updateTableButtonTitle()
                    self.updateOrderButton()
                }
            }
        }
    }

    // MARK: - Fetch

    private func fetchMenuItems() {
        DatabaseService.shared.fetchMenuItems { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let items):
                    self.allMenuItems = items.filter { $0.isAvailable }
                    self.categoryCollectionView?.reloadData()
                    self.applyFilters()
                case .failure(let error):
                    self.showAlert(message: "Không thể tải menu: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Filter

    private func applyFilters() {
        var items = allMenuItems

        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }

        let keyword = (searchBar?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !keyword.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(keyword) }
        }

        filteredMenuItems = items
        productTableView?.reloadData()
    }

    // MARK: - Actions

    @objc private func didTapTable() {
        guard let vc = storyboard?.instantiateViewController(
            withIdentifier: "TableLayoutViewController"
        ) as? TableLayoutViewController else { return }
        vc.delegate = self
        vc.preselectedTableId = selectedTableOption?.id
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func didTapOrder() {
        guard selectedTableOption != nil else {
            showAlert(message: "Vui lòng chọn bàn trước khi tạo đơn hàng.")
            return
        }
        let order = unpaidOrderForCurrentTable
        if order?.statusEnum == .ready {
            confirmPayment(for: order!)
        } else if order?.statusEnum == .pending {
            return  // Nút đã disabled — guard để chắc chắn không tạo thêm order
        } else {
            openOrderPopup()
        }
    }

    private func openOrderPopup() {
        guard let table = selectedTableOption,
              let popup = storyboard?.instantiateViewController(
                withIdentifier: "OrderPopupViewController"
              ) as? OrderPopupViewController else { return }

        popup.selectedTableOption = table
        popup.cartItems = currentCartItems

        popup.onCartUpdated = { [weak self] updatedCart in
            self?.currentCartItems = updatedCart
        }
        popup.onOrderSaved = { [weak self] in
            guard let self else { return }
            // Xoá cart ngay sau khi order được tạo (cả dine-in lẫn takeaway)
            self.ordersByTableId[table.id] = nil
            if table.type == .takeaway {
                TableStateStore.shared.markTableEmpty(id: table.id)
                if self.selectedTableOption?.id == table.id {
                    self.selectedTableOption?.isOccupied = false
                }
            } else {
                // Dine-in: bàn vẫn occupied, chờ bếp xong rồi thanh toán
                TableStateStore.shared.markTableOccupied(id: table.id)
            }
            self.fetchMenuItems()
            self.updateOrderButton()
        }
        popup.modalPresentationStyle = .pageSheet
        present(popup, animated: true)
    }

    // MARK: - Thanh toán dine-in

    private func confirmPayment(for order: Order) {
        let alert = UIAlertController(
            title: "Thanh toán",
            message: "\(order.tableName)\nTổng tiền: \(formatPrice(order.totalAmount))",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Xác nhận", style: .default) { [weak self] _ in
            self?.processPayment(for: order)
        })
        present(alert, animated: true)
    }

    private func processPayment(for order: Order) {
        DatabaseService.shared.markOrderPaid(orderId: order.id) { [weak self] error in
            guard let self else { return }
            DispatchQueue.main.async {
                if let error {
                    self.showAlert(message: "Lỗi thanh toán: \(error.localizedDescription)")
                    return
                }
                // Xoá cart và giải phóng bàn
                self.ordersByTableId[order.tableId] = nil
                TableStateStore.shared.markTableEmpty(id: order.tableId)
                if self.selectedTableOption?.id == order.tableId {
                    self.selectedTableOption?.isOccupied = false
                }
                self.updateTableButtonTitle()
                self.updateOrderButton()
            }
        }
    }

    private func addToCart(item: MenuItem) {
        guard selectedTableOption != nil else {
            showAlert(message: "Vui lòng chọn bàn trước khi thêm sản phẩm.")
            return
        }
        guard item.isAvailable else { return }
        var items = currentCartItems
        if let index = items.firstIndex(where: { $0.menuItem.id == item.id }) {
            items[index].quantity += 1
        } else {
            items.append(CartItem(menuItem: item, quantity: 1))
        }
        currentCartItems = items
    }

    // MARK: - Table button title & order button

    private func updateTableButtonTitle() {
        guard let table = selectedTableOption else {
            if var config = tableButton?.configuration {
                config.title = "Table"
                tableButton?.configuration = config
            } else {
                tableButton?.setTitle("Table", for: .normal)
            }
            return
        }
        // Thêm icon nếu bếp đã xong đơn của bàn này
        let order = activeOrders.first { $0.tableId == table.id && !$0.isPaid }
        let suffix = order?.statusEnum == .ready ? " ✓" : ""
        let title = table.name + suffix
        if var config = tableButton?.configuration {
            config.title = title
            tableButton?.configuration = config
        } else {
            tableButton?.setTitle(title, for: .normal)
        }
        // Đổi màu nút khi bếp xong
        let isReady = order?.statusEnum == .ready
        tableButton?.tintColor = isReady ? UIColor.systemGreen : nil
    }

    private func updateOrderButton() {
        let order = unpaidOrderForCurrentTable
        switch order?.statusEnum {
        case .pending:
            // Bếp đang làm — khoá nút
            orderButton?.isEnabled = false
            if var config = orderButton?.configuration {
                config.title = "Đang làm..."
                config.baseBackgroundColor = UIColor.gray.withAlphaComponent(0.4)
                orderButton?.configuration = config
            } else {
                orderButton?.setTitle("Đang làm...", for: .normal)
                orderButton?.backgroundColor = UIColor.gray.withAlphaComponent(0.4)
            }
        case .ready:
            // Bếp xong — nút thanh toán
            orderButton?.isEnabled = true
            if var config = orderButton?.configuration {
                config.title = "Thanh toán"
                config.baseBackgroundColor = UIColor.systemGreen
                orderButton?.configuration = config
            } else {
                orderButton?.setTitle("Thanh toán", for: .normal)
                orderButton?.backgroundColor = UIColor.systemGreen
            }
        default:
            // Không có order active — bình thường
            orderButton?.isEnabled = true
            if var config = orderButton?.configuration {
                config.title = "Đơn hàng"
                config.baseBackgroundColor = UIColor(hex: "#BD660F")
                orderButton?.configuration = config
            } else {
                orderButton?.setTitle("Đơn hàng", for: .normal)
                orderButton?.backgroundColor = UIColor(hex: "#BD660F")
            }
        }
    }

    // MARK: - Helpers

    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: price)) ?? "\(Int(price))"
        return "\(formatted)đ"
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Thông báo", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TableLayoutViewControllerDelegate

extension POSViewController: TableLayoutViewControllerDelegate {
    func tableLayoutViewController(
        _ viewController: TableLayoutViewController,
        didSelect option: TableOption
    ) {
        selectedTableOption = option
        updateTableButtonTitle()
        updateOrderButton()
    }
}

// MARK: - UICollectionViewDataSource / Delegate (Category bar)

extension POSViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        categories.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath)
        configureCategoryCell(cell, category: categories[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tapped = categories[indexPath.item]
        if tapped == "Tất cả" {
            selectedCategory = nil
        } else {
            selectedCategory = tapped
        }
        collectionView.reloadData()
        applyFilters()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let text = categories[indexPath.item]
        let width = (text as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .medium)]).width + 32
        return CGSize(width: width, height: 36)
    }

    private func configureCategoryCell(_ cell: UICollectionViewCell, category: String) {
        // Clear existing subviews
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let isSelected: Bool
        if category == "Tất cả" {
            isSelected = selectedCategory == nil
        } else {
            isSelected = selectedCategory == category
        }

        cell.contentView.layer.cornerRadius = 18
        cell.contentView.layer.masksToBounds = true

        if isSelected {
            cell.contentView.backgroundColor = UIColor(hex: "#BD660F")
            cell.contentView.layer.borderWidth = 0
        } else {
            cell.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            cell.contentView.layer.borderWidth = 1
            cell.contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        }

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = category
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = isSelected ? .white : UIColor.white.withAlphaComponent(0.72)
        label.textAlignment = .center
        cell.contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: cell.contentView.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -8)
        ])
    }
}

// MARK: - UITableViewDataSource / Delegate (Product list)

extension POSViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredMenuItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath)
        let item = filteredMenuItems[indexPath.row]
        configureProductCell(cell, item: item, row: indexPath.row)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        72
    }

    private func configureProductCell(_ cell: UITableViewCell, item: MenuItem, row: Int) {
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        // Name label
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = item.name
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.numberOfLines = 1

        // Price label
        let priceLabel = UILabel()
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.text = formatPrice(item.price)
        priceLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        priceLabel.textColor = UIColor(hex: "#BD660F") ?? .systemOrange

        // Add button
        let addButton = UIButton(type: .system)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("+", for: .normal)
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        addButton.setTitleColor(.white, for: .normal)
        addButton.backgroundColor = UIColor(hex: "#BD660F")
        addButton.layer.cornerRadius = 16
        addButton.tag = row
        addButton.addTarget(self, action: #selector(didTapAddItem(_:)), for: .touchUpInside)

        cell.contentView.addSubview(nameLabel)
        cell.contentView.addSubview(priceLabel)
        cell.contentView.addSubview(addButton)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: addButton.leadingAnchor, constant: -8),

            priceLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            priceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            priceLabel.trailingAnchor.constraint(lessThanOrEqualTo: addButton.leadingAnchor, constant: -8),

            addButton.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            addButton.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 32),
            addButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    @objc private func didTapAddItem(_ sender: UIButton) {
        let row = sender.tag
        guard row < filteredMenuItems.count else { return }
        let item = filteredMenuItems[row]
        addToCart(item: item)
    }
}

// MARK: - UISearchBarDelegate

extension POSViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applyFilters()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
}


