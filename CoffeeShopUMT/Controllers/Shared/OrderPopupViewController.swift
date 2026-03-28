import UIKit

final class OrderPopupViewController: UIViewController {

    // MARK: - Public state

    var selectedTableOption: TableOption? {
        didSet { if isViewLoaded { updateOrderButtonTitle() } }
    }

    var cartItems: [CartItem] = [] {
        didSet {
            onCartUpdated?(cartItems)
            reloadTableView()
            updateTotals()
        }
    }

    var onCartUpdated: (([CartItem]) -> Void)?
    var onOrderSaved: (() -> Void)?

    // MARK: - Private UI references

    private var cartTableView: UITableView?
    private var closeButton: UIButton?
    private var orderButton: UIButton?
    private var totalItemsLabel: UILabel?
    private var totalPriceLabel: UILabel?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#221910")
        locateViews()
        setupLayout()
        reloadTableView()
        updateTotals()
    }

    // MARK: - Locate views from storyboard hierarchy

    private func locateViews() {
        // 1. TableView
        cartTableView = view.findSubviews(of: UITableView.self).first
        cartTableView?.dataSource = self
        cartTableView?.delegate = self
        cartTableView?.backgroundColor = .clear
        cartTableView?.separatorColor = UIColor.white.withAlphaComponent(0.1)
        cartTableView?.estimatedRowHeight = 72
        cartTableView?.rowHeight = UITableView.automaticDimension

        // 2. Buttons — at viewDidLoad only 2 exist in the hierarchy (close xmark, order button)
        let allButtons = view.findSubviews(of: UIButton.self)
        closeButton = allButtons.first
        orderButton = allButtons.dropFirst().first
        closeButton?.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        orderButton?.addTarget(self, action: #selector(didTapPlaceOrder), for: .touchUpInside)
        updateOrderButtonTitle()

        // 3. Summary labels the user added to the storyboard — found by their placeholder text
        let allLabels = view.findSubviews(of: UILabel.self)
            .filter { !($0.text?.isEmpty ?? true) }
        totalItemsLabel = allLabels.first { $0.text?.hasPrefix("Tổng") == true }
        totalPriceLabel = allLabels.first { $0.text == "Price" }

        // Fallback: create labels if not found in storyboard
        if totalItemsLabel == nil {
            totalItemsLabel = UILabel()
        }
        if totalPriceLabel == nil {
            totalPriceLabel = UILabel()
        }
    }

    // MARK: - Layout fix (programmatic — overrides storyboard fixed-frames)

    private func setupLayout() {
        guard let tableV = cartTableView,
              let container = orderButton?.superview else { return }

        // --- 1. Fix bottom container: was missing height → resolved to 0 → button invisible ---
        container.heightAnchor.constraint(equalToConstant: 66).isActive = true

        // --- 2. Summary row: sits between tableView and bottom container ---
        guard let totalItemsLbl = totalItemsLabel,
              let totalPriceLbl = totalPriceLabel else { return }

        // Move labels into a programmatic summary container so they adapt to any screen height
        totalItemsLbl.removeFromSuperview()
        totalPriceLbl.removeFromSuperview()

        totalItemsLbl.translatesAutoresizingMaskIntoConstraints = false
        totalItemsLbl.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        totalItemsLbl.textColor = UIColor.white.withAlphaComponent(0.72)

        totalPriceLbl.translatesAutoresizingMaskIntoConstraints = false
        totalPriceLbl.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        totalPriceLbl.textColor = .white
        totalPriceLbl.textAlignment = .right

        let summaryRow = UIView()
        summaryRow.translatesAutoresizingMaskIntoConstraints = false
        summaryRow.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        view.addSubview(summaryRow)
        summaryRow.addSubview(totalItemsLbl)
        summaryRow.addSubview(totalPriceLbl)

        // --- 3. "Orders" header label — already has proper storyboard constraints (top/leading to safeArea) ---
        let headerLabel = view.findSubviews(of: UILabel.self)
            .first { $0.font.pointSize >= 30 && $0.font.fontDescriptor.symbolicTraits.contains(.traitBold) }
        let tableTop = headerLabel?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor

        NSLayoutConstraint.activate([
            // TableView fills between header and summary row
            tableV.topAnchor.constraint(equalTo: tableTop, constant: 8),
            tableV.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableV.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableV.bottomAnchor.constraint(equalTo: summaryRow.topAnchor),

            // Summary row: above bottom container, full width, fixed height
            summaryRow.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            summaryRow.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            summaryRow.bottomAnchor.constraint(equalTo: container.topAnchor),
            summaryRow.heightAnchor.constraint(equalToConstant: 44),

            // Summary label positions within summary row
            totalItemsLbl.leadingAnchor.constraint(equalTo: summaryRow.leadingAnchor, constant: 16),
            totalItemsLbl.centerYAnchor.constraint(equalTo: summaryRow.centerYAnchor),

            totalPriceLbl.trailingAnchor.constraint(equalTo: summaryRow.trailingAnchor, constant: -16),
            totalPriceLbl.centerYAnchor.constraint(equalTo: summaryRow.centerYAnchor),
            totalPriceLbl.leadingAnchor.constraint(greaterThanOrEqualTo: totalItemsLbl.trailingAnchor, constant: 8),
        ])
    }

    // MARK: - Reload

    private func reloadTableView() {
        guard isViewLoaded else { return }
        cartTableView?.reloadData()
    }

    // MARK: - Totals

    private func updateTotals() {
        guard isViewLoaded else { return }
        let totalQty = cartItems.reduce(0) { $0 + $1.quantity }
        let totalPrice = cartItems.reduce(0.0) { $0 + $1.menuItem.price * Double($1.quantity) }
        totalItemsLabel?.text = "Tổng cộng: \(totalQty) món"
        totalPriceLabel?.text = formatPrice(totalPrice)
    }

    // MARK: - Actions

    @objc private func didTapClose() {
        dismiss(animated: true)
    }

    @objc private func didTapPlaceOrder() {
        guard let table = selectedTableOption else {
            showAlert(message: "Chưa chọn bàn.")
            return
        }
        guard !cartItems.isEmpty else {
            showAlert(message: "Giỏ hàng trống.")
            return
        }

        if table.type == .takeaway {
            confirmTakeawayPayment(table: table)
        } else {
            sendToKitchen(table: table, paidAt: nil)
        }
    }

    // MARK: - Takeaway: xác nhận thanh toán trước khi gửi bếp

    private func confirmTakeawayPayment(table: TableOption) {
        let total = cartItems.reduce(0.0) { $0 + $1.menuItem.price * Double($1.quantity) }
        let alert = UIAlertController(
            title: "Xác nhận thanh toán",
            message: "Tổng tiền: \(formatPrice(total))\nThu tiền và gửi đơn cho bếp?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Xác nhận", style: .default) { [weak self] _ in
            self?.sendToKitchen(table: table, paidAt: Date())
        })
        present(alert, animated: true)
    }

    // MARK: - Gửi đơn lên Firebase

    private func sendToKitchen(table: TableOption, paidAt: Date?) {
        let orderItems: [OrderItem] = cartItems.map { cart in
            OrderItem(
                menuItemId: cart.menuItem.id ?? "",
                name: cart.menuItem.name,
                price: cart.menuItem.price,
                quantity: cart.quantity,
                note: nil,
                imageURL: cart.menuItem.imageURL
            )
        }
        let total = cartItems.reduce(0.0) { $0 + $1.menuItem.price * Double($1.quantity) }

        DatabaseService.shared.saveOrder(
            tableId: table.id,
            tableName: table.name,
            items: orderItems,
            totalAmount: total,
            paidAt: paidAt
        ) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.onOrderSaved?()
                    // Dine-in: giữ lại cart vì chưa thanh toán
                    // Takeaway: cart xoá (onOrderSaved xử lý bên POSViewController)
                    self.dismiss(animated: true)
                case .failure(let error):
                    self.showAlert(message: "Lỗi lưu đơn hàng: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Cập nhật title nút theo loại bàn

    func updateOrderButtonTitle() {
        let isTakeaway = selectedTableOption?.type == .takeaway
        let title = isTakeaway ? "Thanh toán" : "Gửi bếp"
        orderButton?.setTitle(title, for: .normal)
    }

    @objc private func didTapMinus(_ sender: UIButton) {
        let row = sender.tag
        guard row < cartItems.count else { return }
        if cartItems[row].quantity > 1 {
            cartItems[row].quantity -= 1
        } else {
            cartItems.remove(at: row)
        }
        let snapshot = cartItems
        cartItems = snapshot
    }

    @objc private func didTapPlus(_ sender: UIButton) {
        let row = sender.tag
        guard row < cartItems.count else { return }
        cartItems[row].quantity += 1
        let snapshot = cartItems
        cartItems = snapshot
    }

    @objc private func didTapDelete(_ sender: UIButton) {
        let row = sender.tag
        guard row < cartItems.count else { return }
        cartItems.remove(at: row)
        let snapshot = cartItems
        cartItems = snapshot
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

// MARK: - UITableViewDataSource / Delegate

extension OrderPopupViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cartItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CartItemCell", for: indexPath)
        buildCartCell(cell, at: indexPath.row)
        return cell
    }

    // MARK: - Cell layout (built in code — storyboard prototype uses broken fixed-frames)

    private func buildCartCell(_ cell: UITableViewCell, at row: Int) {
        let cart = cartItems[row]

        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        // Thumbnail image view
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        imageView.image = UIImage(systemName: "cup.and.saucer.fill")
        imageView.tintColor = UIColor.white.withAlphaComponent(0.3)
        loadImage(from: cart.menuItem.imageURL, into: imageView)

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = cart.menuItem.name
        nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.numberOfLines = 2
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let priceLabel = UILabel()
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.text = formatPrice(cart.menuItem.price * Double(cart.quantity))
        priceLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        priceLabel.textColor = UIColor(hex: "#BD660F") ?? .systemOrange
        priceLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, priceLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let minusBtn = makeControlButton(title: "−")
        minusBtn.tag = row
        minusBtn.addTarget(self, action: #selector(didTapMinus(_:)), for: .touchUpInside)

        let qtyLabel = UILabel()
        qtyLabel.translatesAutoresizingMaskIntoConstraints = false
        qtyLabel.text = "\(cart.quantity)"
        qtyLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        qtyLabel.textColor = .white
        qtyLabel.textAlignment = .center
        qtyLabel.setContentHuggingPriority(.required, for: .horizontal)
        qtyLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let plusBtn = makeControlButton(title: "+")
        plusBtn.backgroundColor = UIColor(hex: "#BD660F") ?? .systemOrange
        plusBtn.tag = row
        plusBtn.addTarget(self, action: #selector(didTapPlus(_:)), for: .touchUpInside)

        let deleteBtn = UIButton(type: .system)
        deleteBtn.translatesAutoresizingMaskIntoConstraints = false
        deleteBtn.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteBtn.tintColor = UIColor.systemRed.withAlphaComponent(0.75)
        deleteBtn.tag = row
        deleteBtn.addTarget(self, action: #selector(didTapDelete(_:)), for: .touchUpInside)

        let actionsStack = UIStackView(arrangedSubviews: [minusBtn, qtyLabel, plusBtn, deleteBtn])
        actionsStack.axis = .horizontal
        actionsStack.spacing = 8
        actionsStack.alignment = .center
        actionsStack.translatesAutoresizingMaskIntoConstraints = false

        cell.contentView.addSubview(imageView)
        cell.contentView.addSubview(textStack)
        cell.contentView.addSubview(actionsStack)

        NSLayoutConstraint.activate([
            // Thumbnail
            imageView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 12),
            imageView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 44),
            imageView.heightAnchor.constraint(equalToConstant: 44),

            // Control buttons
            minusBtn.widthAnchor.constraint(equalToConstant: 30),
            minusBtn.heightAnchor.constraint(equalToConstant: 30),
            plusBtn.widthAnchor.constraint(equalToConstant: 30),
            plusBtn.heightAnchor.constraint(equalToConstant: 30),
            deleteBtn.widthAnchor.constraint(equalToConstant: 30),
            deleteBtn.heightAnchor.constraint(equalToConstant: 30),

            actionsStack.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -12),
            actionsStack.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),

            // Text sits between image and actions
            textStack.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
            textStack.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: actionsStack.leadingAnchor, constant: -8),

            cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 68)
        ])
    }

    private func loadImage(from urlString: String?, into imageView: UIImageView) {
        guard let urlString = urlString, let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async { imageView.image = image }
        }.resume()
    }

    private func makeControlButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        btn.layer.cornerRadius = 6
        return btn
    }
}


