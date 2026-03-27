import UIKit
import FirebaseFirestore

final class KitchenDisplayViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Data

    private var allOrders: [Order] = []
    private var ordersListener: ListenerRegistration?

    private var displayedOrders: [Order] {
        switch segmentedControl?.selectedSegmentIndex {
        case 0:  return allOrders.filter { $0.statusEnum == .pending }
        default: return allOrders.filter { $0.statusEnum == .completed }
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupTableView()
        startListening()
    }

    deinit {
        ordersListener?.remove()
    }

    // MARK: - Setup

    private func setupAppearance() {
        view.backgroundColor = UIColor(red: 0.11, green: 0.086, blue: 0.063, alpha: 1)

        segmentedControl?.setTitleTextAttributes(
            [.foregroundColor: UIColor.white.withAlphaComponent(0.7)],
            for: .normal
        )
        segmentedControl?.setTitleTextAttributes(
            [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)],
            for: .selected
        )
        segmentedControl?.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }

    private func setupTableView() {
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.backgroundColor = .clear
        tableView?.separatorStyle = .none
        tableView?.rowHeight = UITableView.automaticDimension
        tableView?.estimatedRowHeight = 250
        tableView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)
    }

    // MARK: - Firestore listener

    private func startListening() {
        ordersListener = DatabaseService.shared.listenToOrders { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let orders):
                    self.allOrders = orders
                    self.tableView?.reloadData()
                case .failure(let error):
                    self.showAlert(message: "Không thể tải đơn hàng: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Actions

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        tableView?.reloadData()
    }

    private func confirmOrder(_ order: Order) {
        DatabaseService.shared.updateOrderStatus(orderId: order.id, status: .completed) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showAlert(message: "Lỗi cập nhật: \(error.localizedDescription)")
                }
                // Listener auto-refreshes — no manual reloadData needed
            }
        }
    }

    // MARK: - Helper

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Thông báo", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension KitchenDisplayViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = displayedOrders.count
        tableView.backgroundView = count == 0 ? emptyStateLabel() : nil
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "OrderCell", for: indexPath
        ) as! OrderTableViewCell

        let order = displayedOrders[indexPath.row]
        cell.configure(with: order)
        cell.onPendingTapped = { [weak self] in
            self?.confirmOrder(order)
        }
        return cell
    }

    // MARK: - Empty state

    private func emptyStateLabel() -> UILabel {
        let lbl = UILabel()
        lbl.text = segmentedControl?.selectedSegmentIndex == 0
            ? "Không có đơn đang chờ"
            : "Chưa có đơn hoàn thành"
        lbl.textColor = UIColor.white.withAlphaComponent(0.4)
        lbl.font = .systemFont(ofSize: 16)
        lbl.textAlignment = .center
        return lbl
    }
}
