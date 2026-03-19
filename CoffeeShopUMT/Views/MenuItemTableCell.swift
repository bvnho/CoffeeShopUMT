import UIKit

final class MenuTableViewCell: UITableViewCell {
    static let identifier = "MenuCell"

    @IBOutlet private weak var itemImageView: UIImageView?
    @IBOutlet private weak var nameLabel: UILabel?
    @IBOutlet private weak var priceLabel: UILabel?
    @IBOutlet private weak var availabilitySwitch: UISwitch?
    @IBOutlet private weak var editButton: UIButton?

    private var currentItemID: String?

    var onToggleAvailability: ((String, Bool) -> Void)?
    var onTapEdit: ((String) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        availabilitySwitch?.onTintColor = UIColor(hex: "#BD660F")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentItemID = nil
        itemImageView?.image = nil
        nameLabel?.text = nil
        priceLabel?.text = nil
        availabilitySwitch?.isOn = false
    }

    func configure(with item: MenuItem) {
        currentItemID = item.id
        nameLabel?.text = item.name
        priceLabel?.text = Self.currencyFormatter.string(from: NSNumber(value: item.price)) ?? "\(Int(item.price)) đ"
        availabilitySwitch?.isOn = item.isAvailable

        if let imageURL = item.imageURL,
           let url = URL(string: imageURL),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            itemImageView?.image = image
        } else {
            itemImageView?.image = UIImage(systemName: "cup.and.saucer.fill")
            itemImageView?.tintColor = UIColor(hex: "#BD660F")
        }
    }

    @IBAction private func availabilitySwitchChanged(_ sender: UISwitch) {
        guard let currentItemID else { return }
        onToggleAvailability?(currentItemID, sender.isOn)
    }

    @IBAction private func editButtonTapped(_ sender: UIButton) {
        guard let currentItemID else { return }
        onTapEdit?(currentItemID)
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "đ"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter
    }()
}

typealias MenuItemTableCell = MenuTableViewCell

// MARK: - UIColor Extension
private extension UIColor {
    convenience init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        guard hexString.count == 6 else { return nil }
        var rgb: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&rgb) else { return nil }
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - Image Loading Extension
