import UIKit

final class MenuListViewController: UIViewController {
    @IBOutlet private weak var categoryCollectionView: UICollectionView?
    @IBOutlet private weak var tableView: UITableView?
    @IBOutlet private weak var searchBar: UISearchBar?
    @IBOutlet private weak var addButton: UIButton?

    private let categories = ["All", "Coffee", "Tea", "Pastries", "Others"]
    private var selectedCategory = "All"
    private var searchKeyword = ""

    private var allItems: [MenuItem] = []
    private var displayItems: [MenuItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupBindings()
        loadMockData()
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
        tableView?.dataSource = self
        tableView?.delegate = self
        categoryCollectionView?.dataSource = self
        categoryCollectionView?.delegate = self
        searchBar?.delegate = self
    }

    private func loadMockData() {
        allItems = [
            MenuItem(id: "1", name: "Caramel Latte", price: 55000, imageURL: nil, category: "Coffee", isAvailable: true),
            MenuItem(id: "2", name: "Americano", price: 40000, imageURL: nil, category: "Coffee", isAvailable: true),
            MenuItem(id: "3", name: "Espresso", price: 35000, imageURL: nil, category: "Coffee", isAvailable: true),
            MenuItem(id: "4", name: "Matcha Latte", price: 60000, imageURL: nil, category: "Tea", isAvailable: true),
            MenuItem(id: "5", name: "Peach Tea", price: 45000, imageURL: nil, category: "Tea", isAvailable: false),
            MenuItem(id: "6", name: "Croissant", price: 30000, imageURL: nil, category: "Pastries", isAvailable: true),
            MenuItem(id: "7", name: "Chocolate Muffin", price: 32000, imageURL: nil, category: "Pastries", isAvailable: true),
            MenuItem(id: "8", name: "Orange Juice", price: 42000, imageURL: nil, category: "Others", isAvailable: true),
            MenuItem(id: "9", name: "Mineral Water", price: 20000, imageURL: nil, category: "Others", isAvailable: true)
        ]

        applyFilterAndSearch()
    }

    private func applyFilterAndSearch() {
        let normalizedSearchText = searchKeyword
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        displayItems = allItems.filter { item in
            let categoryMatched = selectedCategory == "All" || item.category == selectedCategory
            let searchMatched: Bool

            if normalizedSearchText.isEmpty {
                searchMatched = true
            } else {
                searchMatched = item.name.lowercased().contains(normalizedSearchText)
            }

            return categoryMatched && searchMatched
        }

        tableView?.reloadData()
        categoryCollectionView?.reloadData()
    }

    private func updateAvailability(for itemID: String, isAvailable: Bool) {
        guard let index = allItems.firstIndex(where: { $0.id == itemID }) else { return }
        allItems[index].isAvailable = isAvailable
        applyFilterAndSearch()
    }

    private func showAddEditScreen(with item: MenuItem?) {
        let storyboard = UIStoryboard(name: "Admin", bundle: nil)
        guard let addEditViewController = storyboard.instantiateViewController(withIdentifier: "AddMenuItemViewController") as? AddMenuItemViewController else {
            return
        }

        addEditViewController.menuItem = item
        addEditViewController.onSave = { [weak self] newItem in
            self?.upsertMenuItem(newItem)
        }

        addEditViewController.onDelete = { [weak self] itemID in
            self?.deleteItem(itemID: itemID)
        }

        let navigationController = UINavigationController(rootViewController: addEditViewController)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }

    private func upsertMenuItem(_ updatedItem: MenuItem) {
        if let index = allItems.firstIndex(where: { $0.id == updatedItem.id }) {
            allItems[index] = updatedItem
        } else {
            allItems.append(updatedItem)
        }

        applyFilterAndSearch()
    }

    private func deleteItem(itemID: String) {
        allItems.removeAll { $0.id == itemID }
        applyFilterAndSearch()
    }

    @IBAction private func addButtonTapped(_ sender: UIButton) {
        showAddEditScreen(with: nil)
    }
}

extension MenuListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MenuTableViewCell.identifier, for: indexPath) as? MenuTableViewCell else {
            return UITableViewCell()
        }

        let item = displayItems[indexPath.row]
        cell.configure(with: item)

        cell.onToggleAvailability = { [weak self] itemID, isAvailable in
            self?.updateAvailability(for: itemID, isAvailable: isAvailable)
        }

        cell.onTapEdit = { [weak self] itemID in
            guard let self,
                  let selectedItem = self.allItems.first(where: { $0.id == itemID }) else { return }
            self.showAddEditScreen(with: selectedItem)
        }

        return cell
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
