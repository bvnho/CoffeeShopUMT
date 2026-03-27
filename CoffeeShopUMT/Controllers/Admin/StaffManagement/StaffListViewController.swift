import UIKit
import FirebaseAuth

final class StaffListViewController: UIViewController {

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

    func resetTapped(for user: User) {
        let alert = UIAlertController(
            title: "Đặt lại mật khẩu",
            message: "Gửi email đặt lại mật khẩu tới \(user.email)?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Gửi", style: .default) { [weak self] _ in
            Auth.auth().sendPasswordReset(withEmail: user.email) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showAlert(title: "Lỗi", message: error.localizedDescription)
                    } else {
                        self?.showAlert(title: "Thành công", message: "Đã gửi email đặt lại mật khẩu.")
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    func editRoleTapped(for user: User) {
        let alert = UIAlertController(title: "Cập nhật vai trò", message: nil, preferredStyle: .actionSheet)
        for role in ["Admin", "Staff"] {
            alert.addAction(UIAlertAction(title: role, style: .default) { [weak self] _ in
                guard user.role != role else { return }
                DatabaseService.shared.updateUserRole(userId: user.id, role: role) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.showAlert(title: "Lỗi", message: error.localizedDescription)
                        } else {
                            self?.fetchUsers()
                        }
                    }
                }
            })
        }
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        if let pop = alert.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        present(alert, animated: true)
    }

    func disableTapped(for user: User) {
        let next = !user.isActive
        let msg  = next ? "Kích hoạt tài khoản này?" : "Vô hiệu hoá tài khoản này?"
        let alert = UIAlertController(title: "Xác nhận", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        alert.addAction(UIAlertAction(title: "Xác nhận", style: .destructive) { [weak self] _ in
            DatabaseService.shared.toggleUserStatus(userId: user.id, isActive: next) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showAlert(title: "Lỗi", message: error.localizedDescription)
                    } else {
                        self?.fetchUsers()
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    /// Avatar tap: Admin xem / cập nhật ảnh nhân viên.
    /// Kiến trúc đồng bộ: upload lên Firebase Storage → lưu download URL
    /// vào Firestore "Users/{uid}.profileImageURL" → Staff app tự đọc field
    /// này trong StaffProfileViewController.loadUserData() khi viewWillAppear.
    func avatarTapped(for user: User) {
        showAlert(
            title: user.fullName,
            message: "Để thay ảnh: upload lên Firebase Storage, lưu URL vào Firestore Users/\(user.id).profileImageURL — Staff app tự đồng bộ khi mở lại màn hình Profile."
        )
    }
}
