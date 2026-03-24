import UIKit
import FirebaseFirestore
import FirebaseStorage

final class AddMenuItemViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
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
    private let storage = Storage.storage()
    private let imagePicker = UIImagePickerController()

    private var selectedCategory: String?
    private var selectedImage: UIImage?
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: 1000)
        super.viewDidLoad()
        setupAppearance()
        setupMode()
        setupDismissKeyboardGesture()
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

            if let imageURL = existingItem.imageURL,
               let url = URL(string: imageURL) {
                loadImage(from: url)
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
            uploadImage(selectedImage) { [weak self] result in
                switch result {
                case .success(let imageURL):
                    saveData(imageURL)
                case .failure(let error):
                    self?.setLoading(false)
                    self?.showAlert(message: "Upload ảnh thất bại: \(error.localizedDescription)")
                }
            }
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

    private func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "AddMenu", code: -1, userInfo: [NSLocalizedDescriptionKey: "Không nén được ảnh."])))
            return
        }

        let imageRef = storage.reference().child("MenuImages/\(UUID().uuidString).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        imageRef.putData(imageData, metadata: metadata) { _, error in
            if let error {
                completion(.failure(error))
                return
            }

            imageRef.downloadURL { url, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                guard let url else {
                    completion(.failure(NSError(domain: "AddMenu", code: -2, userInfo: [NSLocalizedDescriptionKey: "Không lấy được URL ảnh."])))
                    return
                }

                completion(.success(url.absoluteString))
            }
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
