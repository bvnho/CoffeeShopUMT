import UIKit

final class OrderTableViewCell: UITableViewCell {

    // MARK: - IBOutlets (connected in Staff.storyboard prototype cell)

    @IBOutlet private weak var cardView: UIView!
    @IBOutlet private weak var badgeView: UIView!
    @IBOutlet private weak var badgeLabel: UILabel!
    @IBOutlet private weak var tableLabel: UILabel!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var orderIdLabel: UILabel!
    @IBOutlet private weak var itemsStackView: UIStackView!
    @IBOutlet private weak var pendingButton: UIButton!

    // MARK: - Public callback

    var onPendingTapped: (() -> Void)?

    // MARK: - Private — "Đã hoàn thành" label (added programmatically)

    private lazy var completedLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = "✓  Đã hoàn thành"
        lbl.font = .systemFont(ofSize: 15, weight: .semibold)
        lbl.textColor = UIColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 1)
        lbl.textAlignment = .center
        lbl.isHidden = true
        return lbl
    }()

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        selectionStyle = .none
        setupLayout()
        pendingButton?.addTarget(self, action: #selector(handlePendingTap), for: .touchUpInside)
    }

    // MARK: - Layout fix
    // The pending button is `fixedFrame="YES"` in the storyboard → no Auto Layout constraints.
    // We add them here to anchor it below itemsStackView and close the vertical chain.

    private func setupLayout() {
        guard let pBtn = pendingButton, let cv = cardView, let stk = itemsStackView else { return }

        pBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pBtn.topAnchor.constraint(equalTo: stk.bottomAnchor, constant: 16),
            pBtn.leadingAnchor.constraint(equalTo: cv.leadingAnchor, constant: 8),
            pBtn.trailingAnchor.constraint(equalTo: cv.trailingAnchor, constant: -8),
            pBtn.heightAnchor.constraint(equalToConstant: 50),
            pBtn.bottomAnchor.constraint(equalTo: cv.bottomAnchor, constant: -12),
        ])

        // "Đã hoàn thành" sits in the same slot as the button
        cv.addSubview(completedLabel)
        NSLayoutConstraint.activate([
            completedLabel.topAnchor.constraint(equalTo: stk.bottomAnchor, constant: 16),
            completedLabel.leadingAnchor.constraint(equalTo: cv.leadingAnchor, constant: 8),
            completedLabel.trailingAnchor.constraint(equalTo: cv.trailingAnchor, constant: -8),
            completedLabel.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    // MARK: - Configure

    func configure(with order: Order) {
        // Badge
        badgeLabel?.text = order.orderType
        badgeView?.backgroundColor = order.tableId == "takeaway"
            ? UIColor(red: 0.10, green: 0.35, blue: 0.20, alpha: 1)
            : UIColor(red: 0.30, green: 0.19, blue: 0.08, alpha: 1)

        // Table
        tableLabel?.text = order.tableId == "takeaway" ? "" : order.tableName
        tableLabel?.isHidden = order.tableId == "takeaway"

        // Time
        timeLabel?.text = relativeTime(from: order.createdAt)

        // Order ID (first 6 chars, uppercase)
        orderIdLabel?.text = "#\(order.id.prefix(6).uppercased())"

        // Items — rebuild stack dynamically
        itemsStackView?.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for item in order.items {
            itemsStackView?.addArrangedSubview(makeItemRow(item))
        }

        // Status
        let isPending = order.statusEnum == .pending
        pendingButton?.isHidden = !isPending
        completedLabel.isHidden = isPending
    }

    // MARK: - Item row builder

    private func makeItemRow(_ item: OrderItem) -> UIView {
        let qtyLabel = UILabel()
        qtyLabel.text = "\(item.quantity)x"
        qtyLabel.font = .boldSystemFont(ofSize: 16)
        qtyLabel.textColor = UIColor(red: 0.74, green: 0.40, blue: 0.06, alpha: 1)
        qtyLabel.setContentHuggingPriority(.required, for: .horizontal)
        qtyLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let nameLabel = UILabel()
        nameLabel.text = item.name
        nameLabel.font = .boldSystemFont(ofSize: 16)
        nameLabel.textColor = .white
        nameLabel.numberOfLines = 2

        let noteLabel = UILabel()
        noteLabel.text = item.note ?? ""
        noteLabel.font = .systemFont(ofSize: 14)
        noteLabel.textColor = UIColor(white: 0.61, alpha: 1)
        noteLabel.numberOfLines = 1
        noteLabel.isHidden = (item.note ?? "").isEmpty

        let descStack = UIStackView(arrangedSubviews: [nameLabel, noteLabel])
        descStack.axis = .vertical
        descStack.spacing = 4

        let row = UIStackView(arrangedSubviews: [qtyLabel, descStack])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12
        return row
    }

    // MARK: - Action

    @objc private func handlePendingTap() {
        onPendingTapped?()
    }

    // MARK: - Time helper

    private func relativeTime(from date: Date) -> String {
        let secs = Int(Date().timeIntervalSince(date))
        if secs < 60  { return "Vừa xong" }
        if secs < 3600 { return "\(secs / 60) phút trước" }
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }
}
