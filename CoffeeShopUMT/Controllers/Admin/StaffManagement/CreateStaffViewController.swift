import UIKit
import FirebaseAuth
import PhotosUI

final class CreateStaffViewController: UIViewController {

    @IBOutlet weak var avatarButton: UIButton!
    @IBOutlet weak var grantButton: UIButton!
    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    /// Đặt trước khi push để vào chế độ chỉnh sửa
    var editingUser: User?

    private var selectedImage: UIImage?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        styleAvatarButton()
        setupMode()
    }

    private func styleAvatarButton() {
        avatarButton.imageView?.contentMode = .scaleAspectFill
        avatarButton.clipsToBounds = true
        avatarButton.layer.cornerRadius = avatarButton.bounds.width / 2
        avatarButton.contentHorizontalAlignment = .fill
        avatarButton.contentVerticalAlignment = .fill
    }

    private func setupMode() {
        if let user = editingUser {
            // Edit mode
            title = "Edit Staff"
            grantButton?.setTitle("Xác nhận", for: .normal)
            fullNameTextField.text = user.fullName
            emailTextField.text    = user.email
            emailTextField.isEnabled = false
            emailTextField.alpha     = 0.5
            passwordTextField.isHidden = true
            // Load avatar if available
            if let url = user.profileImageURL, !url.isEmpty {
                loadAvatarIntoButton(url)
            }
        } else {
            title = "Create Staff"
            grantButton?.setTitle("Grant Account", for: .normal)
            emailTextField.placeholder = "staff@coffeeshopumt.com"
        }
    }

    private func loadAvatarIntoButton(_ urlString: String) {
        if urlString.hasPrefix("data:image") {
            let b64 = urlString.components(separatedBy: ",").last ?? ""
            if let data = Data(base64Encoded: b64), let img = UIImage(data: data) {
                setAvatarImage(img)
            }
        } else if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { self?.setAvatarImage(img) }
            }.resume()
        }
    }

    private func setAvatarImage(_ image: UIImage) {
        avatarButton.setImage(image, for: .normal)
        avatarButton.layer.cornerRadius = avatarButton.bounds.width / 2
    }

    // MARK: - Avatar

    @IBAction func avatarButtonTapped(_ sender: UIButton) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Submit

    @IBAction func grantAccountTapped(_ sender: UIButton) {
        let fullName = fullNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email    = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text ?? ""

        guard !fullName.isEmpty else {
            showAlert(title: "Thiếu thông tin", message: "Vui lòng nhập họ và tên.")
            return
        }

        if editingUser == nil {
            guard !email.isEmpty, !password.isEmpty else {
                showAlert(title: "Thiếu thông tin", message: "Vui lòng điền đầy đủ tất cả các trường.")
                return
            }
            guard email.lowercased().hasSuffix("@coffeeshopumt.com") else {
                showAlert(title: "Email không hợp lệ", message: "Email phải có định dạng ...@coffeeshopumt.com")
                return
            }
        }

        setSubmitting(true)
        let imageBase64 = selectedImage.flatMap { compressToBase64($0) }

        if let user = editingUser {
            // Edit mode: update Firestore only
            let imageToSave = imageBase64 ?? user.profileImageURL
            DatabaseService.shared.updateStaffInfo(userId: user.id, fullName: fullName, profileImageURL: imageToSave) { [weak self] error in
                DispatchQueue.main.async {
                    self?.setSubmitting(false)
                    if let error {
                        self?.showAlert(title: "Lỗi", message: error.localizedDescription)
                    } else {
                        self?.popOrDismiss()
                    }
                }
            }
        } else {
            // Create mode: create Firebase Auth + Firestore document
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if let error {
                        self.setSubmitting(false)
                        self.showAlert(title: "Lỗi", message: error.localizedDescription)
                        return
                    }
                    guard let uid = result?.user.uid else {
                        self.setSubmitting(false)
                        self.showAlert(title: "Lỗi", message: "Không lấy được user ID.")
                        return
                    }
                    DatabaseService.shared.createNewUserDocument(
                        uid: uid,
                        fullName: fullName,
                        email: email,
                        role: "Staff",
                        isActive: true,
                        profileImageURL: imageBase64
                    ) { dbError in
                        DispatchQueue.main.async {
                            if let dbError {
                                self.setSubmitting(false)
                                self.showAlert(title: "Lỗi", message: dbError.localizedDescription)
                                return
                            }
                            self.popOrDismiss()
                        }
                    }
                }
            }
        }
    }

    @IBAction func cancelTapped(_ sender: UIButton) {
        popOrDismiss()
    }

    // MARK: - Helpers

    private func setSubmitting(_ isSubmitting: Bool) {
        grantButton?.isEnabled = !isSubmitting
        grantButton?.alpha     = isSubmitting ? 0.5 : 1.0
    }

    private func popOrDismiss() {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func compressToBase64(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.6) else { return nil }
        return "data:image/jpeg;base64," + data.base64EncodedString()
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension CreateStaffViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self, let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self.selectedImage = image
                self.setAvatarImage(image)
            }
        }
    }
}
