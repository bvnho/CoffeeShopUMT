import UIKit
import FirebaseAuth

final class StaffListViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    private var users: [User] = []
    private var filteredUsers: [User] = []

    private var isSearching: Bool {
        let keyword = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !keyword.isEmpty
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        fetchUsers()
    }

    private func fetchUsers() {
        DatabaseService.shared.fetchStaffAndAdmins { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let fetchedUsers):
                    self.users = fetchedUsers
                    self.applySearch()
                case .failure(let error):
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func applySearch() {
        guard isSearching else {
            filteredUsers = users
            tableView.reloadData()
            return
        }

        let keyword = (searchBar.text ?? "").lowercased()
        filteredUsers = users.filter {
            $0.fullName.lowercased().contains(keyword) ||
            $0.email.lowercased().contains(keyword)
        }
        tableView.reloadData()
    }

    private func currentDataSource() -> [User] {
        return isSearching ? filteredUsers : users
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension StaffListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentDataSource().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "StaffCell", for: indexPath) as? StaffCell else {
            return UITableViewCell()
        }

        let user = currentDataSource()[indexPath.row]
        cell.delegate = self
        cell.configure(with: user)
        return cell
    }
}

extension StaffListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applySearch()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension StaffListViewController: StaffCellDelegate {
    func resetTapped(for user: User) {
        Auth.auth().sendPasswordReset(withEmail: user.email) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }
                self?.showAlert(title: "Success", message: "Password reset email sent to \(user.email).")
            }
        }
    }

    func editRoleTapped(for user: User) {
        let alert = UIAlertController(title: "Update Role", message: "Select a role", preferredStyle: .actionSheet)

        let adminAction = UIAlertAction(title: "Admin", style: .default) { [weak self] _ in
            self?.updateRoleIfNeeded(user: user, newRole: "Admin")
        }

        let staffAction = UIAlertAction(title: "Staff", style: .default) { [weak self] _ in
            self?.updateRoleIfNeeded(user: user, newRole: "Staff")
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alert.addAction(adminAction)
        alert.addAction(staffAction)
        alert.addAction(cancelAction)

        if let popover = alert.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }

    private func updateRoleIfNeeded(user: User, newRole: String) {
        guard user.role != newRole else { return }

        DatabaseService.shared.updateUserRole(userId: user.id, role: newRole) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }
                self?.fetchUsers()
            }
        }
    }

    func disableTapped(for user: User) {
        let nextStatus = !user.isActive
        let message = nextStatus
            ? "Do you want to enable this account?"
            : "Do you want to disable this account?"

        let alert = UIAlertController(title: "Confirm", message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive) { [weak self] _ in
            DatabaseService.shared.toggleUserStatus(userId: user.id, isActive: nextStatus) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                        return
                    }
                    self?.fetchUsers()
                }
            }
        })

        present(alert, animated: true)
    }
}