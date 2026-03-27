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

        itemImageView?.layer.cornerRadius = 8
        itemImageView?.clipsToBounds = true
        itemImageView?.contentMode = .scaleAspectFill
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

        itemImageView?.image = UIImage(systemName: "cup.and.saucer.fill")
        itemImageView?.tintColor = UIColor(hex: "#BD660F")

        if let imageString = item.imageURL, !imageString.isEmpty {
            if imageString.starts(with: "http") {
                if let url = URL(string: imageString) {
                    URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self?.itemImageView?.image = image
                            }
                        }
                    }.resume()
                }
            } else if let data = Data(base64Encoded: imageString), let image = UIImage(data: data) {
                itemImageView?.image = image
            }
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
