import UIKit
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

final class StaffProfileViewController: UIViewController {

    // MARK: - IBOutlets (connected in Staff.storyboard)

    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var roleLabel: UILabel!
    @IBOutlet private weak var logoutButton: UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        loadUserData()
        setupAvatarTap()
        logoutButton?.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload khi quay lại từ màn khác (phòng trường hợp avatar vừa cập nhật)
        applyLocalUser()
    }

    // MARK: - Appearance

    private func setupAppearance() {
        avatarImageView.layer.cornerRadius = 60
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.borderWidth = 2
        avatarImageView.layer.borderColor = UIColor(red: 0.74, green: 0.40, blue: 0.06, alpha: 1).cgColor
    }

    // MARK: - Load user data

    private func loadUserData() {
        // Nếu có cache trong UserDefaults → hiển thị ngay
        if let cachedUser = AuthService.shared.currentUser {
            apply(user: cachedUser)
        }

        // Fetch mới nhất từ Firestore theo UID hiện tại
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("Users").document(uid).getDocument { [weak self] snapshot, _ in
            guard let data = snapshot?.data() else { return }
            let user = User(
                id: uid,
                fullName: data["fullName"] as? String ?? "Nhân viên",
                email: data["email"] as? String ?? "",
                role: data["role"] as? String ?? "Staff",
                salary: data["salary"] as? Double,
                isActive: data["isActive"] as? Bool ?? true,
                profileImageURL: data["profileImageURL"] as? String
            )
            AuthService.shared.saveCurrentUser(user)
            DispatchQueue.main.async { self?.apply(user: user) }
        }
    }

    /// Áp dụng dữ liệu từ cache cục bộ (không gọi network)
    private func applyLocalUser() {
        if let user = AuthService.shared.currentUser { apply(user: user) }
    }

    private func apply(user: User) {
        nameLabel?.text = user.fullName
        roleLabel?.text = user.role

        guard let urlString = user.profileImageURL, !urlString.isEmpty else { return }

        if urlString.hasPrefix("data:image") {
            // Base64 được lưu cục bộ sau khi chọn ảnh
            let base64Part = urlString.components(separatedBy: ",").last ?? ""
            if let data = Data(base64Encoded: base64Part),
               let image = UIImage(data: data) {
                avatarImageView.image = image
            }
        } else if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data = data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async { self?.avatarImageView.image = image }
            }.resume()
        }
    }

    // MARK: - Avatar tap

    private func setupAvatarTap() {
        avatarImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleAvatarTap))
        avatarImageView.addGestureRecognizer(tap)
    }

    @objc private func handleAvatarTap() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Logout

    @objc private func handleLogout() {
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

extension StaffProfileViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.avatarImageView.image = image
                self?.persistAvatar(image)
            }
        }
    }

    /// Mock upload: nén ảnh và lưu base64 vào UserDefaults.
    /// Thực tế: upload lên Firebase Storage rồi lưu download URL.
    private func persistAvatar(_ image: UIImage) {
        guard var user = AuthService.shared.currentUser else { return }
        let resized = resize(image: image, maxWidth: 400)
        guard let data = resized.jpegData(compressionQuality: 0.5) else { return }
        let base64 = data.base64EncodedString()
        user.profileImageURL = "data:image/jpeg;base64,\(base64)"
        AuthService.shared.saveCurrentUser(user)
    }

    private func resize(image: UIImage, maxWidth: CGFloat) -> UIImage {
        guard image.size.width > maxWidth else { return image }
        let scale = maxWidth / image.size.width
        let newSize = CGSize(width: maxWidth, height: image.size.height * scale)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
