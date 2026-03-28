import UIKit

final class OrderDetailViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var orderIdLabel: UILabel!
    @IBOutlet weak var orderTypeLabel: UILabel!
    @IBOutlet weak var orderTableLabel: UILabel!
    @IBOutlet weak var orderTimeLabel: UILabel!
    @IBOutlet weak var statusBadgeLabel: UILabel!
    @IBOutlet weak var subtotalValueLabel: UILabel!
    @IBOutlet weak var taxValueLabel: UILabel!
    @IBOutlet weak var totalValueLabel: UILabel!

    // MARK: - Input

    var order: Order!

    // MARK: - Private

    private var itemsTableView: UITableView?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        wireBackButton()
        populateOrderInfo()
        locateAndSetupItemsTable()
    }

    // MARK: - Wire back button

    private func wireBackButton() {
        view.findSubviews(of: UIButton.self).first?
            .addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Populate order info

    private func populateOrderInfo() {
        orderIdLabel?.text    = "#\(order.id.prefix(8).uppercased())"
        orderTypeLabel?.text  = order.orderType          // "Tại quán" / "Mang về"
        orderTableLabel?.text = order.tableName
        orderTimeLabel?.text  = formatDateTime(order.createdAt)

        configureStatusBadge()

        let subtotal = order.items.reduce(0.0) { $0 + $1.price * Double($1.quantity) }
        subtotalValueLabel?.text = formatPrice(subtotal)
        taxValueLabel?.text      = formatPrice(0)
        totalValueLabel?.text    = formatPrice(order.totalAmount)
    }

    private func configureStatusBadge() {
        guard let label = statusBadgeLabel else { return }
        if order.isPaid {
            label.text = "ĐÃ THANH TOÁN"
            label.backgroundColor = UIColor(hex: "#0D9488")
        } else if order.statusEnum == .ready {
            label.text = "SẴN SÀNG"
            label.backgroundColor = .appSuccess
        } else {
            label.text = "ĐANG LÀM"
            label.backgroundColor = .appAccent
        }
        label.textColor          = .white
        label.layer.cornerRadius = 6
        label.clipsToBounds      = true
    }

    // MARK: - Items table view

    private func locateAndSetupItemsTable() {
        // Storyboard có sẵn 1 UITableView trong scene này
        itemsTableView = view.findSubviews(of: UITableView.self).first
        itemsTableView?.dataSource         = self
        itemsTableView?.delegate           = self
        itemsTableView?.backgroundColor    = .clear
        itemsTableView?.separatorColor     = UIColor.white.withAlphaComponent(0.12)
        itemsTableView?.rowHeight          = UITableView.automaticDimension
        itemsTableView?.estimatedRowHeight = 60
        itemsTableView?.isScrollEnabled    = false
        itemsTableView?.register(UITableViewCell.self, forCellReuseIdentifier: "OrderItemCell")
    }

    // MARK: - Helpers

    private func formatPrice(_ price: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: price)) ?? "\(Int(price))") + "đ"
    }

    private func formatDateTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm • dd/MM/yyyy"
        return f.string(from: date)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension OrderDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        order?.items.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OrderItemCell", for: indexPath)
        let item = order.items[indexPath.row]

        var config = UIListContentConfiguration.subtitleCell()
        config.text          = "\(item.quantity)× \(item.name)"
        config.secondaryText = item.note ?? ""
        config.textProperties.color          = .appTextPrimary
        config.secondaryTextProperties.color = .appTextSecondary
        config.secondaryTextProperties.font  = .systemFont(ofSize: 12)

        let priceLabel = UILabel()
        priceLabel.text      = formatPrice(item.price * Double(item.quantity))
        priceLabel.textColor = .appAccent
        priceLabel.font      = .systemFont(ofSize: 14, weight: .semibold)
        priceLabel.sizeToFit()

        cell.contentConfiguration = config
        cell.accessoryView        = priceLabel
        cell.backgroundColor      = .clear
        cell.selectionStyle       = .none
        return cell
    }
}
