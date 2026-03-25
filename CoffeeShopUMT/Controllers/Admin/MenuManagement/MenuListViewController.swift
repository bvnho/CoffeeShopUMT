import UIKit
import FirebaseFirestore

final class MenuListViewController: UIViewController {
    @IBOutlet private weak var categoryCollectionView: UICollectionView?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet private weak var searchBar: UISearchBar?
    @IBOutlet private weak var addButton: UIButton?
    
    private let categories = ["All", "Coffee", "Tea", "Pastries", "Others"]
    private var selectedCategory = "All"
    private var searchKeyword = ""
    
    var menuItems: [MenuItem] = []
    private var displayItems: [MenuItem] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupBindings()
        observeMenuItems()
    }
    
    deinit {
        listener?.remove()
    }
    
    private func setupAppearance() {
        view.backgroundColor = UIColor(hex: "#221910")
        navigationItem.title = "Menu Management"
        
        searchBar?.barTintColor = UIColor(hex: "#221910")
        searchBar?.searchTextField.backgroundColor = UIColor(hex: "#120E0A")
        searchBar?.searchTextField.textColor = .white
        searchBar?.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search menu items...",
            attributes: [.foregroundColor: UIColor(hex: "#334155") ?? UIColor.gray]
        )
        
        addButton?.backgroundColor = UIColor(hex: "#BD660F")
        addButton?.setTitleColor(.white, for: .normal)
        addButton?.layer.cornerRadius = (addButton?.frame.height ?? 44) / 2
        
        tableView?.backgroundColor = .clear
        categoryCollectionView?.backgroundColor = .clear
    }
    
    private func setupBindings() {
        tableView.dataSource = self
        tableView.delegate = self
        categoryCollectionView?.dataSource = self
        categoryCollectionView?.delegate = self
        searchBar?.delegate = self
    }
    
    private func observeMenuItems() {
        listener?.remove()
        listener = db.collection("MenuItems").addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error {
                self.showAlert(message: "Không thể tải dữ liệu menu: \(error.localizedDescription)")
                return
            }
            
            self.menuItems = snapshot?.documents.compactMap { try? $0.data(as: MenuItem.self) } ?? []
            self.applyFilterAndSearch()
        }
    }
    
    private func applyFilterAndSearch() {
        let normalizedSearchText = searchKeyword
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        
        displayItems = menuItems.filter { item in
            let categoryMatched = selectedCategory == "All" || item.category == selectedCategory
            let searchMatched: Bool
            
            if normalizedSearchText.isEmpty {
                searchMatched = true
            } else {
                searchMatched = item.name.lowercased().contains(normalizedSearchText)
            }
            
            return categoryMatched && searchMatched
        }
        
        tableView.reloadData()
        categoryCollectionView?.reloadData()
    }
    
    private func updateAvailability(for itemID: String, isAvailable: Bool) {
        db.collection("MenuItems").document(itemID).updateData(["isAvailable": isAvailable])
    }
    
    private func showAddEditScreen(with item: MenuItem?) {
        let storyboard = UIStoryboard(name: "Admin", bundle: nil)
        guard let addEditViewController = storyboard.instantiateViewController(withIdentifier: "AddMenuItemViewController") as? AddMenuItemViewController else {
            return
        }
        
        addEditViewController.menuItem = item
        
        if let navigationController = navigationController {
            navigationController.pushViewController(addEditViewController, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: addEditViewController)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }
}

extension MenuListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = displayItems[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MenuTableViewCell.identifier, for: indexPath) as? MenuTableViewCell else {
            return UITableViewCell()
        }

        cell.configure(with: item)

        cell.onToggleAvailability = { [weak self] itemID, isAvailable in
            self?.updateAvailability(for: itemID, isAvailable: isAvailable)
        }

        cell.onTapEdit = { [weak self] itemID in
            guard let self,
                  let selectedItem = self.menuItems.first(where: { $0.id == itemID }) else { return }
            self.showAddEditScreen(with: selectedItem)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showAddEditScreen(with: displayItems[indexPath.row])
    }
}

extension MenuListViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        categories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as UICollectionViewCell? else {
            return UICollectionViewCell()
        }

        let title = categories[indexPath.item]
        var content = UIListContentConfiguration.cell()
        content.text = title
        content.textProperties.font = .systemFont(ofSize: 14, weight: .semibold)
        content.textProperties.color = .white
        content.textProperties.alignment = .center
        cell.contentConfiguration = content

        cell.layer.cornerRadius = 14
        let isActive = selectedCategory == title
        cell.backgroundColor = isActive ? UIColor(hex: "#BD660F") : UIColor(hex: "#334155")

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCategory = categories[indexPath.item]
        applyFilterAndSearch()
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let title = categories[indexPath.item]
        let width = title.size(withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .semibold)]).width + 28
        return CGSize(width: width, height: collectionView.bounds.height - 8)
    }
}

extension MenuListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchKeyword = searchText
        applyFilterAndSearch()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
}

private extension MenuListViewController {
    func showAlert(message: String) {
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
