import UIKit
import FirebaseFirestore

final class OrdersViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var filterSegmentedControl: UISegmentedControl!
    @IBOutlet weak var ordersTableView: UITableView!
    @IBOutlet weak var totalOrdersValueLabel: UILabel!
    @IBOutlet weak var avgTicketValueLabel: UILabel!

    // MARK: - Data

    private var allOrders: [Order] = []
    private var displayedOrders: [Order] = []
    private var ordersListener: ListenerRegistration?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupTableView()
        wireBackButton()
        filterSegmentedControl?.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        startListeningOrders()
    }

    deinit {
        ordersListener?.remove()
    }

    // MARK: - Setup

    private func setupAppearance() {
        view.backgroundColor = .appBackground
        ordersTableView?.backgroundColor = .clear
        ordersTableView?.separatorStyle  = .none

        filterSegmentedControl?.setTitleTextAttributes(
            [.foregroundColor: UIColor.appTextSecondary], for: .normal)
        filterSegmentedControl?.setTitleTextAttributes(
            [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)],
            for: .selected)
    }

    private func setupTableView() {
        ordersTableView?.dataSource = self
        ordersTableView?.delegate   = self
        ordersTableView?.rowHeight  = 120
        ordersTableView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
    }

    private func wireBackButton() {
        // Nút back là UIButton đầu tiên trong header
        view.findSubviews(of: UIButton.self).first?
            .addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    // MARK: - Listener

    private func startListeningOrders() {
        ordersListener = DatabaseService.shared.listenToOrders { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let orders) = result {
                    self?.allOrders = orders
                    self?.applyFilter()
                }
            }
        }
    }

    // MARK: - Filter

    @objc private func segmentChanged() {
        applyFilter()
    }

    private func applyFilter() {
        switch filterSegmentedControl?.selectedSegmentIndex {
        case 0:  displayedOrders = allOrders.filter { !$0.isPaid }   // Processing: chưa thanh toán
        case 1:  displayedOrders = allOrders.filter {  $0.isPaid }   // Completed: đã thanh toán
        default: displayedOrders = allOrders
        }
        updateStats()
        ordersTableView?.reloadData()
    }

    private func updateStats() {
        totalOrdersValueLabel?.text = "\(displayedOrders.count)"
        let avg = displayedOrders.isEmpty
            ? 0.0
            : displayedOrders.reduce(0.0) { $0 + $1.totalAmount } / Double(displayedOrders.count)
        avgTicketValueLabel?.text = formatPrice(avg)
    }

    // MARK: - Navigation

    @objc private func backTapped() {
        // Nếu là root của NavController (present từ Dashboard) → dismiss cả NavController
        if navigationController?.viewControllers.first === self {
            navigationController?.dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    private func pushOrderDetail(_ order: Order) {
        let sb = UIStoryboard(name: "Admin", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "OrderDetailViewController")
                as? OrderDetailViewController else { return }
        vc.order = order
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Cell configuration

    private func configureCell(_ cell: AdminOrderTableViewCell, with order: Order) {
        cell.orderIdLabel?.text = "#\(order.id.prefix(8).uppercased())"
        cell.tableLabel?.text   = order.tableName
        cell.timeLabel?.text    = timeString(from: order.createdAt)

        let names = order.items.prefix(2).map { $0.name }.joined(separator: ", ")
        let extra = order.items.count > 2 ? " +\(order.items.count - 2)" : ""
        cell.itemsSummaryLabel?.text = names + extra

        configureStatusBadge(cell.statusBadgeLabel, order: order)
        cell.backgroundColor = .clear
        cell.selectionStyle  = .none
    }

    private func configureStatusBadge(_ label: UILabel?, order: Order) {
        guard let label else { return }
        if order.isPaid {
            label.text            = "ĐÃ THANH TOÁN"
            label.backgroundColor = UIColor(hex: "#0D9488")
        } else if order.statusEnum == .ready {
            label.text            = "SẴN SÀNG"
            label.backgroundColor = .appSuccess
        } else {
            label.text            = "ĐANG LÀM"
            label.backgroundColor = .appAccent
        }
        label.textColor         = .white
        label.layer.cornerRadius = 6
        label.clipsToBounds      = true
    }

    // MARK: - Helpers

    private func formatPrice(_ price: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: price)) ?? "\(Int(price))") + "đ"
    }

    private func timeString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm • dd/MM"
        return f.string(from: date)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension OrdersViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = displayedOrders.count
        tableView.backgroundView = count == 0 ? emptyLabel() : nil
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AdminOrderCell", for: indexPath)
            as! AdminOrderTableViewCell
        configureCell(cell, with: displayedOrders[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        pushOrderDetail(displayedOrders[indexPath.row])
    }

    private func emptyLabel() -> UILabel {
        let lbl = UILabel()
        lbl.text          = "Không có đơn nào"
        lbl.textColor     = .appTextSecondary
        lbl.font          = .systemFont(ofSize: 16)
        lbl.textAlignment = .center
        return lbl
    }
}
