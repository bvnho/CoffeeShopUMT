import UIKit
import FirebaseAuth
import PhotosUI

final class StaffListViewController: UIViewController {

    private var pendingAvatarUser: User?

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    private var users: [User] = []
    private var filteredUsers: [User] = []

    private var isSearching: Bool {
        let kw = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !kw.isEmpty
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        searchBar.delegate   = self
        tableView.delegate   = self
        tableView.dataSource = self
        tableView.rowHeight  = 179          // keep storyboard fixed height
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUsers()
    }

    // MARK: - Appearance

    /// Fix nền trắng: ghi đè systemBackgroundColor bằng màu tối ứng dụng.
    private func setupAppearance() {
        view.backgroundColor          = .appBackground   // #221910
        tableView.backgroundColor     = .clear
        tableView.separatorStyle      = .none

        // Search bar styling
        searchBar.barStyle = .black
        searchBar.searchTextField.backgroundColor = UIColor(hex: "#2a1a0d")
        searchBar.searchTextField.textColor        = .white
        searchBar.searchTextField.tintColor        = .appAccent
        (searchBar.searchTextField.leftView as? UIImageView)?.tintColor = .appTextSecondary
    }

    // MARK: - Data

    private func fetchUsers() {
        DatabaseService.shared.fetchStaffAndAdmins { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let list):
                    self.users = list
                    self.applySearch()
                case .failure(let err):
                    self.showAlert(title: "Lỗi", message: err.localizedDescription)
                }
            }
        }
    }

    private func applySearch() {
        if isSearching {
            let kw = (searchBar.text ?? "").lowercased()
            filteredUsers = users.filter {
                $0.fullName.lowercased().contains(kw) || $0.email.lowercased().contains(kw)
            }
        } else {
            filteredUsers = users
        }
        tableView.reloadData()
    }

    private func currentDataSource() -> [User] { isSearching ? filteredUsers : users }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension StaffListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        currentDataSource().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "StaffCell", for: indexPath) as? StaffCell else {
            return UITableViewCell()
        }
        cell.delegate = self
        cell.configure(with: currentDataSource()[indexPath.row])
        return cell
    }
}

// MARK: - UISearchBarDelegate

extension StaffListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) { applySearch() }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) { searchBar.resignFirstResponder() }
}

// MARK: - StaffCellDelegate

extension StaffListViewController: StaffCellDelegate {

    func editTapped(for user: User) {
        let sb = UIStoryboard(name: "Admin", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "CreateStaffViewController")
                as? CreateStaffViewController else { return }
        vc.editingUser = user
        navigationController?.pushViewController(vc, animated: true)
    }

    func deleteTapped(for user: User) {
        let alert = UIAlertController(
            title: "Xóa nhân viên",
            message: "Bạn có chắc muốn xóa \(user.fullName) khỏi hệ thống?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Xóa", style: .destructive) { [weak self] _ in
            DatabaseService.shared.deleteStaffDocument(userId: user.id) { error in
                DispatchQueue.main.async {
                    if let error {
                        self?.showAlert(title: "Lỗi", message: error.localizedDescription)
                    } else {
                        self?.fetchUsers()
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    func avatarTapped(for user: User) {
        pendingAvatarUser = user
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension StaffListViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let user = pendingAvatarUser,
              let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else {
            pendingAvatarUser = nil
            return
        }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self, let image = object as? UIImage else { return }
            guard let data = image.jpegData(compressionQuality: 0.6) else { return }
            let base64 = "data:image/jpeg;base64," + data.base64EncodedString()
            DatabaseService.shared.updateUserProfileImage(userId: user.id, profileImageURL: base64) { error in
                DispatchQueue.main.async {
                    self.pendingAvatarUser = nil
                    if let error {
                        self.showAlert(title: "Lỗi", message: error.localizedDescription)
                    } else {
                        self.fetchUsers()
                    }
                }
            }
        }
    }
}
