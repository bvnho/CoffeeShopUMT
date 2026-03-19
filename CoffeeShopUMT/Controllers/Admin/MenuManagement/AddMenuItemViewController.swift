import UIKit

final class AddMenuItemViewController: UIViewController {
    @IBOutlet private weak var titleLabel: UILabel?
    @IBOutlet private weak var itemNameTextField: UITextField?
    @IBOutlet private weak var priceTextField: UITextField?
    @IBOutlet private weak var descriptionTextView: UITextView?
    @IBOutlet private weak var availableSwitch: UISwitch?
    @IBOutlet private weak var deleteButton: UIButton?

    @IBOutlet private weak var coffeeButton: UIButton?
    @IBOutlet private weak var teaButton: UIButton?
    @IBOutlet private weak var pastriesButton: UIButton?
    @IBOutlet private weak var othersButton: UIButton?

    var menuItem: MenuItem?
    var onSave: ((MenuItem) -> Void)?
    var onDelete: ((String) -> Void)?

    private let categories = ["Coffee", "Tea", "Pastries", "Others"]
    private var selectedCategory = "Coffee"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupMode()
        setupDismissKeyboardGesture()
    }

    private func setupAppearance() {
        view.backgroundColor = UIColor(hex: "#221910")

        itemNameTextField?.textColor = .white
        priceTextField?.textColor = .white
        descriptionTextView?.textColor = .white

        itemNameTextField?.backgroundColor = UIColor(hex: "#120E0A")
        priceTextField?.backgroundColor = UIColor(hex: "#120E0A")
        descriptionTextView?.backgroundColor = UIColor(hex: "#120E0A")

        priceTextField?.keyboardType = .numberPad
        availableSwitch?.onTintColor = UIColor(hex: "#BD660F")

        deleteButton?.backgroundColor = UIColor(hex: "#EF4444")
        deleteButton?.setTitleColor(.white, for: .normal)
        deleteButton?.layer.cornerRadius = 8
    }

    private func setupMode() {
        guard let existingItem = menuItem else {
            titleLabel?.text = "Add"
            deleteButton?.isHidden = true
            selectedCategory = "Coffee"
            availableSwitch?.isOn = true
            updateCategoryButtonsUI()
            return
        }

        titleLabel?.text = "Edit"
        deleteButton?.isHidden = false

        itemNameTextField?.text = existingItem.name
        priceTextField?.text = String(Int(existingItem.price))
        descriptionTextView?.text = ""
        availableSwitch?.isOn = existingItem.isAvailable
        selectedCategory = existingItem.category
        updateCategoryButtonsUI()
    }

    private func setupDismissKeyboardGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutside))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func updateCategoryButtonsUI() {
        let buttonPairs: [(UIButton?, String)] = [
            (coffeeButton, categories[0]),
            (teaButton, categories[1]),
            (pastriesButton, categories[2]),
            (othersButton, categories[3])
        ]

        buttonPairs.forEach { button, category in
            let isSelected = category == selectedCategory
            button?.backgroundColor = isSelected ? UIColor(hex: "#BD660F") : UIColor(hex: "#334155")
            button?.setTitleColor(.white, for: .normal)
            button?.layer.cornerRadius = 8
        }
    }

    @objc private func handleTapOutside() {
        view.endEditing(true)
    }

    @IBAction private func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction private func saveButtonTapped(_ sender: UIButton) {
        let trimmedName = itemNameTextField?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedPrice = priceTextField?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !trimmedName.isEmpty, !trimmedPrice.isEmpty else {
            showAlert(message: "Vui lòng nhập Tên món và Giá.")
            return
        }

        guard let price = Double(trimmedPrice) else {
            showAlert(message: "Giá không hợp lệ.")
            return
        }

        let createdItem = MenuItem(
            id: menuItem?.id ?? UUID().uuidString,
            name: trimmedName,
            price: price,
            imageURL: menuItem?.imageURL,
            category: selectedCategory,
            isAvailable: availableSwitch?.isOn ?? true
        )

        onSave?(createdItem)
        dismiss(animated: true)
    }

    @IBAction private func deleteButtonTapped(_ sender: UIButton) {
        guard let itemID = menuItem?.id else { return }
        onDelete?(itemID)
        dismiss(animated: true)
    }

    @IBAction private func categoryButtonTapped(_ sender: UIButton) {
        switch sender {
        case coffeeButton:
            selectedCategory = "Coffee"
        case teaButton:
            selectedCategory = "Tea"
        case pastriesButton:
            selectedCategory = "Pastries"
        case othersButton:
            selectedCategory = "Others"
        default:
            break
        }

        updateCategoryButtonsUI()
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Thông báo", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

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
