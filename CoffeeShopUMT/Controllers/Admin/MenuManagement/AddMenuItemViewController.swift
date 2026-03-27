import UIKit
import FirebaseFirestore

final class AddMenuItemViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet private weak var scrollView: UIScrollView?
    @IBOutlet private weak var titleLabel: UILabel?
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var choosePhotoButton: UIButton!
    @IBOutlet weak var itemNameTextField: UITextField!
    @IBOutlet var categoryButtons: [UIButton]!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var availableSwitch: UISwitch!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!

    @IBOutlet private weak var coffeeButton: UIButton?
    @IBOutlet private weak var teaButton: UIButton?
    @IBOutlet private weak var pastriesButton: UIButton?
    @IBOutlet private weak var othersButton: UIButton?

    var menuItem: MenuItem?
    var onSave: ((MenuItem) -> Void)?
    var onDelete: ((String) -> Void)?

    private let categories = ["Coffee", "Tea", "Pastries", "Others"]
    private let db = Firestore.firestore()
    private let imagePicker = UIImagePickerController()

    private var selectedCategory: String?
    private var selectedImage: UIImage?
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupLayout()
        setupMode()
        setupDismissKeyboardGesture()
        scrollView?.keyboardDismissMode = .onDrag
    }

    private func setupAppearance() {
        view.backgroundColor = UIColor(hex: "#221910")

        itemNameTextField.textColor = .white
        priceTextField.textColor = .white
        descriptionTextView.textColor = .white

        itemNameTextField.backgroundColor = UIColor(hex: "#120E0A")
        priceTextField.backgroundColor = UIColor(hex: "#120E0A")
        descriptionTextView.backgroundColor = UIColor(hex: "#120E0A")
        itemImageView.layer.cornerRadius = 8
        itemImageView.clipsToBounds = true

        priceTextField.keyboardType = .decimalPad
        availableSwitch.onTintColor = UIColor(hex: "#BD660F")

        deleteButton.backgroundColor = UIColor(hex: "#EF4444")
        deleteButton.setTitleColor(.white, for: .normal)
        deleteButton.layer.cornerRadius = 8

        choosePhotoButton.layer.cornerRadius = 8
        choosePhotoButton.backgroundColor = UIColor(hex: "#334155")

        saveButton.layer.cornerRadius = 8
        saveButton.backgroundColor = UIColor(hex: "#BD660F")

        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        saveButton.addSubview(activityIndicator)
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }

    private func setupMode() {
        if let existingItem = menuItem {
            titleLabel?.text = "Edit"
            deleteButton.isHidden = false
            saveButton.setTitle("Update", for: .normal)

            itemNameTextField.text = existingItem.name
            priceTextField.text = String(existingItem.price)
            descriptionTextView.text = existingItem.descriptionText
            availableSwitch.isOn = existingItem.isAvailable
            selectedCategory = existingItem.category

            if let imageString = existingItem.imageURL, !imageString.isEmpty {
                if imageString.starts(with: "http"),
                   let url = URL(string: imageString) {
                    loadImage(from: url)
                } else if let data = Data(base64Encoded: imageString),
                          let image = UIImage(data: data) {
                    itemImageView.image = image
                }
            }
            updateCategoryButtonsUI()
            return
        }

        titleLabel?.text = "Add"
        deleteButton.isHidden = true
        saveButton.setTitle("Save", for: .normal)
        itemNameTextField.text = ""
        priceTextField.text = ""
        descriptionTextView.text = ""
        availableSwitch.isOn = true
        selectedCategory = nil
        itemImageView.image = UIImage(systemName: "photo")
        updateCategoryButtonsUI()
    }

    // MARK: - Layout

    private func setupLayout() {
        guard let sv = scrollView,
              let contentView = sv.subviews.first else { return }

        // ── A. Add missing scrollView trailing constraint ─────────────────────────
        sv.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        // ── B. Locate views without direct outlets ────────────────────────────────
        let childLabels   = contentView.subviews.compactMap { $0 as? UILabel }
        let nameLabel     = childLabels.first { $0.text == "Item Name" }
        let categoryLabel = childLabels.first { $0.text == "Category" }
        let priceLabel    = childLabels.first { $0.text == "Price" }
        let descLabel     = childLabels.first { $0.text == "Description" }
        let categoryStack = coffeeButton?.superview          // UAy-HP-YPd
        let availableStack = availableSwitch.superview       // 20R-g6-8gd

        // ── C. Wipe all storyboard constraints (fixedFrame + conflicts + hardcoded) ─
        NSLayoutConstraint.deactivate(contentView.constraints)
        contentView.subviews.forEach { NSLayoutConstraint.deactivate($0.constraints) }

        // ── D. Ensure TAMIC = NO for every view we'll constrain ──────────────────
        [nameLabel, categoryLabel, priceLabel, descLabel,
         itemImageView, choosePhotoButton, itemNameTextField,
         categoryStack, priceTextField, descriptionTextView,
         availableStack, saveButton, deleteButton]
            .compactMap { $0 }
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let pad   = CGFloat(20)
        let lead  = contentView.leadingAnchor
        let trail = contentView.trailingAnchor

        // ── Image row ─────────────────────────────────────────────────────────────
        NSLayoutConstraint.activate([
            itemImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            itemImageView.leadingAnchor.constraint(equalTo: lead, constant: pad),
            itemImageView.heightAnchor.constraint(equalToConstant: 80),
            itemImageView.widthAnchor.constraint(equalToConstant: 90),

            choosePhotoButton.centerYAnchor.constraint(equalTo: itemImageView.centerYAnchor),
            choosePhotoButton.leadingAnchor.constraint(equalTo: itemImageView.trailingAnchor, constant: 16),
            choosePhotoButton.trailingAnchor.constraint(equalTo: trail, constant: -pad),
            choosePhotoButton.heightAnchor.constraint(equalToConstant: 44),
        ])

        // ── Item Name ─────────────────────────────────────────────────────────────
        var prevBottom: NSLayoutYAxisAnchor = itemImageView.bottomAnchor
        if let nl = nameLabel {
            NSLayoutConstraint.activate([
                nl.topAnchor.constraint(equalTo: prevBottom, constant: 20),
                nl.leadingAnchor.constraint(equalTo: lead, constant: pad),
            ])
            prevBottom = nl.bottomAnchor
        }
        NSLayoutConstraint.activate([
            itemNameTextField.topAnchor.constraint(equalTo: prevBottom, constant: 8),
            itemNameTextField.leadingAnchor.constraint(equalTo: lead, constant: pad),
            itemNameTextField.trailingAnchor.constraint(equalTo: trail, constant: -pad),
            itemNameTextField.heightAnchor.constraint(equalToConstant: 44),
        ])

        // ── Category ──────────────────────────────────────────────────────────────
        prevBottom = itemNameTextField.bottomAnchor
        if let cl = categoryLabel {
            NSLayoutConstraint.activate([
                cl.topAnchor.constraint(equalTo: prevBottom, constant: 16),
                cl.leadingAnchor.constraint(equalTo: lead, constant: pad),
            ])
            prevBottom = cl.bottomAnchor
        }
        if let cs = categoryStack {
            cs.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                cs.topAnchor.constraint(equalTo: prevBottom, constant: 8),
                cs.leadingAnchor.constraint(equalTo: lead, constant: pad),
                cs.trailingAnchor.constraint(equalTo: trail, constant: -pad),
                cs.heightAnchor.constraint(equalToConstant: 44),
            ])
            prevBottom = cs.bottomAnchor
        }

        // ── Price ─────────────────────────────────────────────────────────────────
        if let pl = priceLabel {
            NSLayoutConstraint.activate([
                pl.topAnchor.constraint(equalTo: prevBottom, constant: 16),
                pl.leadingAnchor.constraint(equalTo: lead, constant: pad),
            ])
            prevBottom = pl.bottomAnchor
        }
        NSLayoutConstraint.activate([
            priceTextField.topAnchor.constraint(equalTo: prevBottom, constant: 8),
            priceTextField.leadingAnchor.constraint(equalTo: lead, constant: pad),
            priceTextField.trailingAnchor.constraint(equalTo: trail, constant: -pad),
            priceTextField.heightAnchor.constraint(equalToConstant: 44),
        ])

        // ── Description ───────────────────────────────────────────────────────────
        prevBottom = priceTextField.bottomAnchor
        if let dl = descLabel {
            NSLayoutConstraint.activate([
                dl.topAnchor.constraint(equalTo: prevBottom, constant: 16),
                dl.leadingAnchor.constraint(equalTo: lead, constant: pad),
            ])
            prevBottom = dl.bottomAnchor
        }
        NSLayoutConstraint.activate([
            descriptionTextView.topAnchor.constraint(equalTo: prevBottom, constant: 8),
            descriptionTextView.leadingAnchor.constraint(equalTo: lead, constant: pad),
            descriptionTextView.trailingAnchor.constraint(equalTo: trail, constant: -pad),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 120),
        ])

        // ── Available in POS ──────────────────────────────────────────────────────
        prevBottom = descriptionTextView.bottomAnchor
        if let as_ = availableStack {
            as_.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                as_.topAnchor.constraint(equalTo: prevBottom, constant: 20),
                as_.leadingAnchor.constraint(equalTo: lead, constant: pad),
                as_.trailingAnchor.constraint(equalTo: trail, constant: -pad),
                as_.heightAnchor.constraint(equalToConstant: 44),
            ])
            prevBottom = as_.bottomAnchor
        }

        // ── Save ──────────────────────────────────────────────────────────────────
        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: prevBottom, constant: 24),
            saveButton.leadingAnchor.constraint(equalTo: lead, constant: pad),
            saveButton.trailingAnchor.constraint(equalTo: trail, constant: -pad),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
        ])

        // ── Delete (anchors contentView bottom = dynamic scroll height) ───────────
        NSLayoutConstraint.activate([
            deleteButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 12),
            deleteButton.leadingAnchor.constraint(equalTo: lead, constant: pad),
            deleteButton.trailingAnchor.constraint(equalTo: trail, constant: -pad),
            deleteButton.heightAnchor.constraint(equalToConstant: 50),
            deleteButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ])
    }

    private func setupDismissKeyboardGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutside))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    private func updateCategoryButtonsUI() {
        if let categoryButtons, categoryButtons.count == categories.count {
            for (index, button) in categoryButtons.enumerated() {
                let category = categories[index]
                let isSelected = category == selectedCategory
                button.backgroundColor = isSelected ? UIColor(hex: "#BD660F") : UIColor(hex: "#334155")
                button.setTitleColor(.white, for: .normal)
                button.layer.cornerRadius = 8
                button.layer.borderColor = UIColor.white.cgColor
                button.layer.borderWidth = isSelected ? 1 : 0
            }
            return
        }

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
            button?.layer.borderColor = UIColor.white.cgColor
            button?.layer.borderWidth = isSelected ? 1 : 0
        }
    }

    @objc private func handleTapOutside() {
        view.endEditing(true)
    }

    @IBAction private func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func choosePhotoButtonTapped(_ sender: UIButton) {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            showAlert(message: "Thiết bị không hỗ trợ Photo Library.")
            return
        }

        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }

    @IBAction private func saveButtonTapped(_ sender: UIButton) {
        let trimmedName = itemNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedPrice = priceTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedDescription = descriptionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            showAlert(message: "Vui lòng nhập tên món.")
            return
        }

        guard !trimmedPrice.isEmpty else {
            showAlert(message: "Vui lòng nhập giá.")
            return
        }

        guard let selectedCategory, !selectedCategory.isEmpty else {
            showAlert(message: "Vui lòng chọn danh mục.")
            return
        }

        guard let price = Double(trimmedPrice) else {
            showAlert(message: "Giá không hợp lệ.")
            return
        }

        setLoading(true)

        let saveData: (String?) -> Void = { [weak self] uploadedImageURL in
            guard let self else { return }
            let itemToSave = MenuItem(
                id: self.menuItem?.id,
                name: trimmedName,
                category: selectedCategory,
                price: price,
                descriptionText: trimmedDescription,
                isAvailable: self.availableSwitch.isOn,
                imageURL: uploadedImageURL
            )
            self.saveMenuItem(itemToSave)
        }

        if let selectedImage {
            guard let base64String = encodedImageString(from: selectedImage) else {
                setLoading(false)
                showAlert(message: "Không thể xử lý ảnh. Vui lòng chọn ảnh khác.")
                return
            }
            saveData(base64String)
        } else {
            saveData(menuItem?.imageURL)
        }
    }

    @IBAction private func deleteButtonTapped(_ sender: UIButton) {
        guard let itemID = menuItem?.id else { return }

        let alert = UIAlertController(
            title: "Xóa món",
            message: "Bạn có chắc muốn xóa món này không?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel))
        alert.addAction(UIAlertAction(title: "Xóa", style: .destructive, handler: { [weak self] _ in
            guard let self else { return }
            self.setLoading(true)
            self.db.collection("MenuItems").document(itemID).delete { error in
                self.setLoading(false)
                if let error {
                    self.showAlert(message: "Xóa thất bại: \(error.localizedDescription)")
                    return
                }
                self.onDelete?(itemID)
                self.dismiss(animated: true)
            }
        }))

        present(alert, animated: true)
    }

    @IBAction private func categoryButtonTapped(_ sender: UIButton) {
        if let categoryButtons,
           let index = categoryButtons.firstIndex(of: sender),
           index < categories.count {
            selectedCategory = categories[index]
            updateCategoryButtonsUI()
            return
        }

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

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        selectedImage = image
        itemImageView.image = image
        picker.dismiss(animated: true)
    }

    private func encodedImageString(from image: UIImage) -> String? {
        let resizedImage = resizedImageKeepingAspectRatio(from: image, maxWidth: 640)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.3) else {
            return nil
        }
        return imageData.base64EncodedString()
    }

    private func resizedImageKeepingAspectRatio(from image: UIImage, maxWidth: CGFloat) -> UIImage {
        guard image.size.width > maxWidth else { return image }

        let scale = maxWidth / image.size.width
        let newSize = CGSize(width: maxWidth, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func saveMenuItem(_ item: MenuItem) {
        do {
            if let itemID = item.id, !itemID.isEmpty {
                try db.collection("MenuItems").document(itemID).setData(from: item, merge: true) { [weak self] error in
                    self?.handleSaveResult(error: error, savedItem: item)
                }
            } else {
                _ = try db.collection("MenuItems").addDocument(from: item) { [weak self] error in
                    self?.handleSaveResult(error: error, savedItem: item)
                }
            }
        } catch {
            setLoading(false)
            showAlert(message: "Lưu dữ liệu thất bại: \(error.localizedDescription)")
        }
    }

    private func handleSaveResult(error: Error?, savedItem: MenuItem) {
        setLoading(false)
        if let error {
            showAlert(message: "Lưu món thất bại: \(error.localizedDescription)")
            return
        }

        onSave?(savedItem)
        dismiss(animated: true)
    }

    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data,
                  let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.itemImageView.image = image
            }
        }.resume()
    }

    private func setLoading(_ isLoading: Bool) {
        saveButton.isEnabled = !isLoading
        choosePhotoButton.isEnabled = !isLoading
        deleteButton.isEnabled = !isLoading

        if isLoading {
            let currentTitle = saveButton.title(for: .normal) ?? "Save"
            saveButton.accessibilityLabel = currentTitle
            saveButton.setTitle("Saving...", for: .normal)
            activityIndicator.center = CGPoint(x: saveButton.bounds.midX, y: saveButton.bounds.midY)
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            let title = menuItem == nil ? "Save" : "Update"
            saveButton.setTitle(title, for: .normal)
        }
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
