import UIKit
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class AdminProfileViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var emailLabel: UILabel!
    @IBOutlet private weak var roleBadgeLabel: UILabel!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAvatarAppearance()
        setupAvatarTap()
        loadCurrentUser()
    }

    // MARK: - Setup

    private func setupAvatarAppearance() {
        avatarImageView.layer.cornerRadius  = 60
        avatarImageView.layer.borderWidth   = 3
        avatarImageView.layer.borderColor   = UIColor.appAccent.cgColor
        avatarImageView.clipsToBounds       = true
        avatarImageView.contentMode         = .scaleAspectFill
        avatarImageView.backgroundColor     = .appDisabled
        avatarImageView.image               = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor           = .appTextSecondary

        // Style role badge border (cannot set borderColor via storyboard)
        if let badge = roleBadgeLabel?.superview {
            badge.layer.borderColor = UIColor.appAccent.cgColor
        }
    }

    private func setupAvatarTap() {
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleAvatarTap))
        )
    }

    // MARK: - Load User Data

    private func loadCurrentUser() {
        if let cached = AuthService.shared.currentUser { apply(user: cached) }

        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("Users").document(uid).getDocument { [weak self] snap, _ in
            DispatchQueue.main.async {
                guard let data = snap?.data() else { return }
                let user = User(
                    id: uid,
                    fullName: data["fullName"] as? String ?? "Admin",
                    email: data["email"] as? String ?? "",
                    role: data["role"] as? String ?? "Admin",
                    salary: data["salary"] as? Double,
                    isActive: data["isActive"] as? Bool ?? true,
                    profileImageURL: data["profileImageURL"] as? String
                )
                AuthService.shared.saveCurrentUser(user)
                self?.apply(user: user)
            }
        }
    }

    private func apply(user: User) {
        nameLabel.text      = user.fullName
        emailLabel.text     = user.email
        roleBadgeLabel.text = "VAI TRÒ: \(user.role.uppercased())"

        guard let urlStr = user.profileImageURL, !urlStr.isEmpty else { return }
        loadAvatarImage(from: urlStr)
    }

    private func loadAvatarImage(from urlStr: String) {
        if urlStr.hasPrefix("data:image") {
            let b64 = urlStr.components(separatedBy: ",").last ?? ""
            if let data = Data(base64Encoded: b64), let img = UIImage(data: data) {
                avatarImageView.image = img
            }
        } else if let url = URL(string: urlStr) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { self?.avatarImageView.image = img }
            }.resume()
        }
    }

    // MARK: - Avatar Editing

    @objc private func handleAvatarTap() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter       = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func persistAvatar(_ image: UIImage) {
        avatarImageView.image = image
        guard let uid = Auth.auth().currentUser?.uid,
              let data = image.jpegData(compressionQuality: 0.75) else { return }

        let b64 = "data:image/jpeg;base64," + data.base64EncodedString()

        // Update Firestore
        Firestore.firestore().collection("Users").document(uid)
            .updateData(["profileImageURL": b64])

        // Update local cache
        if var user = AuthService.shared.currentUser {
            user = User(id: user.id,
                        fullName: user.fullName,
                        email: user.email,
                        role: user.role,
                        salary: user.salary,
                        isActive: user.isActive,
                        profileImageURL: b64)
            AuthService.shared.saveCurrentUser(user)
        }
    }

    // MARK: - IBActions

    @IBAction private func handleBack(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction private func handleLogout(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Đăng xuất",
            message: "Bạn có chắc muốn đăng xuất không?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Đăng xuất", style: .destructive) { [weak self] _ in
            guard let self else { return }
            AuthService.shared.logout(from: self)
        })
        present(alert, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension AdminProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let img = object as? UIImage else { return }
            DispatchQueue.main.async { self?.persistAvatar(img) }
        }
    }
}
