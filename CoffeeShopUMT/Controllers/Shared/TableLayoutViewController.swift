import UIKit

protocol TableLayoutViewControllerDelegate: AnyObject {
    func tableLayoutViewController(_ viewController: TableLayoutViewController, didSelect option: TableOption)
}

final class TableLayoutViewModel {
    // TODO: Add table layout logic
}

final class TableLayoutViewController: UIViewController {
    private let viewModel = TableLayoutViewModel()
    private let tableStateStore = TableStateStore.shared
    private var options: [TableOption] = []

    weak var delegate: TableLayoutViewControllerDelegate?
    var preselectedTableId: String?

    private var collectionView: UICollectionView? {
        findCollectionView(in: view)
    }

    private var closeButton: UIButton? {
        findCloseButton(in: view)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarItem.title = "Tables"
        self.tabBarItem.image = UIImage(systemName: "square.grid.2x2")
        setupUI()
        configureCollectionView()
        configureCloseButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadOptions()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#221910")
        navigationItem.title = "Tables"
    }

    private func configureCollectionView() {
        collectionView?.dataSource = self
        collectionView?.delegate = self
        collectionView?.backgroundColor = .clear
    }

    private func configureCloseButton() {
        closeButton?.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
    }

    private func reloadOptions() {
        options = tableStateStore.getOptions()
        collectionView?.reloadData()
    }

    @objc private func didTapClose() {
        navigationController?.popViewController(animated: true)
    }

    private func findCollectionView(in rootView: UIView) -> UICollectionView? {
        if let targetCollectionView = rootView as? UICollectionView {
            return targetCollectionView
        }

        for child in rootView.subviews {
            if let targetCollectionView = findCollectionView(in: child) {
                return targetCollectionView
            }
        }

        return nil
    }

    private func findCloseButton(in rootView: UIView) -> UIButton? {
        if let button = rootView as? UIButton {
            return button
        }

        for child in rootView.subviews {
            if let button = findCloseButton(in: child) {
                return button
            }
        }

        return nil
    }

    private func statusText(for option: TableOption) -> String {
        option.isOccupied ? "Có người" : "Trống"
    }

    private func configureCell(_ cell: UICollectionViewCell, with option: TableOption) {
        cell.contentView.layer.cornerRadius = 14
        cell.contentView.layer.masksToBounds = true

        let isPreselected = option.id == preselectedTableId

        if isPreselected {
            cell.contentView.layer.borderWidth = 2
            cell.contentView.layer.borderColor = (UIColor(hex: "#BD660F") ?? .systemOrange).cgColor
            cell.contentView.backgroundColor = UIColor(hex: "#BD660F")?.withAlphaComponent(0.22)
        } else {
            cell.contentView.layer.borderWidth = 1
            cell.contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.24).cgColor
            cell.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        }

        let labels = cell.contentView.findSubviews(of: UILabel.self)

        if labels.count >= 2 {
            labels[0].text = option.name
            labels[1].text = statusText(for: option)
            labels[0].textColor = .white
            labels[1].textColor = .white.withAlphaComponent(0.72)
            labels[0].font = UIFont.systemFont(ofSize: 24, weight: .semibold)
            labels[1].font = UIFont.systemFont(ofSize: 16, weight: .medium)
        }
    }
}

extension TableLayoutViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        options.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TableCell", for: indexPath)
        configureCell(cell, with: options[indexPath.item])
        return cell
    }
}

extension TableLayoutViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tappedOption = options[indexPath.item]
        guard let selectedOption = tableStateStore.selectOption(id: tappedOption.id) else {
            return
        }

        delegate?.tableLayoutViewController(self, didSelect: selectedOption)
        navigationController?.popViewController(animated: true)
    }
}

extension TableLayoutViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let option = options[indexPath.item]

        if option.type == .takeaway {
            // Full-width row — sits alone on its own line
            return CGSize(width: collectionView.bounds.width, height: 80)
        }

        // 3-column grid for dine-in tables
        // 2 inter-item gaps of 10pt between 3 columns
        let totalInteritemSpacing: CGFloat = 10 * 2
        let itemWidth = floor((collectionView.bounds.width - totalInteritemSpacing) / 3)
        return CGSize(width: itemWidth, height: 120)
    }
}


