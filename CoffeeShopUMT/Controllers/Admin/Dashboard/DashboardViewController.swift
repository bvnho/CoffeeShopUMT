import UIKit
import FirebaseFirestore

final class DashboardViewController: UIViewController {

    // MARK: - Data

    private var allOrders: [Order] = []
    private var ordersListener: ListenerRegistration?

    // MARK: - Located views

    private var revValueLabel: UILabel?
    private var ordValueLabel: UILabel?
    private var compValueLabel: UILabel?
    private var bsNames: [UILabel] = []
    private var bsSolds: [UILabel] = []
    private var cardRevenueView: UIView?
    private var cardOrdersView: UIView?
    private var cardCompletedView: UIView?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        addProfileTapButton()
        locateStoryboardViews()
        setupCardGestures()
        startListeningOrders()
    }

    deinit {
        ordersListener?.remove()
    }

    // MARK: - Locate storyboard views

    private func locateStoryboardViews() {
        let allLabels = view.findSubviews(of: UILabel.self)

        // Cards value labels — khớp placeholder text trong storyboard
        revValueLabel  = allLabels.first { $0.text == "1.000.000 VNĐ" }
        ordValueLabel  = allLabels.first { $0.text == "12" }
        compValueLabel = allLabels.first { $0.text == "45" }

        // Best seller name & sold labels
        let bsNameTexts = ["Ethiopian Blend", "Caramel Latte", "Choco Croissant"]
        let bsSoldTexts = ["842 sold", "756 sold", "512 sold"]
        bsNames = bsNameTexts.compactMap { t in allLabels.first { $0.text == t } }
        bsSolds = bsSoldTexts.compactMap { t in allLabels.first { $0.text == t } }

        // 3 cards — tìm bằng tag đặt trong storyboard
        cardRevenueView   = view.viewWithTag(101)
        cardOrdersView    = view.viewWithTag(102)
        cardCompletedView = view.viewWithTag(103)

        // "View All" button
        view.findSubviews(of: UIButton.self)
            .first { $0.title(for: .normal) == "View All" }?
            .addTarget(self, action: #selector(openOrders), for: .touchUpInside)
    }

    // MARK: - Card tap gestures

    private func setupCardGestures() {
        let pairs: [(UIView?, Selector)] = [
            (cardRevenueView,   #selector(openRevenue)),
            (cardOrdersView,    #selector(openOrders)),
            (cardCompletedView, #selector(openOrders))
        ]
        for (card, sel) in pairs {
            guard let card else { continue }
            card.isUserInteractionEnabled = true
            card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: sel))
        }
    }

    // MARK: - Firestore listener

    private func startListeningOrders() {
        ordersListener = DatabaseService.shared.listenToOrders { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let orders) = result {
                    self?.allOrders = orders
                    self?.updateDashboard()
                }
            }
        }
    }

    // MARK: - Update UI

    private func updateDashboard() {
        let cal      = Calendar.current
        let today    = cal.startOfDay(for: Date())
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!

        let paidToday = allOrders.filter {
            guard let paid = $0.paidAt else { return false }
            return paid >= today && paid < tomorrow
        }
        // "Đang xử lý" = chỉ đơn bếp đang làm (pending), không tính đơn ready chờ thanh toán
        let activePending = allOrders.filter { $0.statusEnum == .pending }

        revValueLabel?.text  = formatPrice(paidToday.reduce(0) { $0 + $1.totalAmount })
        ordValueLabel?.text  = "\(activePending.count)"
        compValueLabel?.text = "\(paidToday.count)"

        updateBestSellers()
    }

    private func updateBestSellers() {
        // All-time: gom theo menuItemId, tổng quantity của tất cả đơn đã thanh toán
        var tally: [String: (name: String, qty: Int)] = [:]
        for order in allOrders where order.isPaid {
            for item in order.items {
                let key = item.menuItemId.isEmpty ? item.name : item.menuItemId
                var entry = tally[key] ?? (item.name, 0)
                entry.qty += item.quantity
                tally[key] = entry
            }
        }
        let top3 = Array(tally.values.sorted { $0.qty > $1.qty }.prefix(3))

        for (i, lbl) in bsNames.enumerated() { lbl.text = i < top3.count ? top3[i].name  : "-" }
        for (i, lbl) in bsSolds.enumerated() { lbl.text = i < top3.count ? "\(top3[i].qty) sold" : "0 sold" }
    }

    // MARK: - Navigation

    @objc private func openRevenue() {
        let sb = UIStoryboard(name: "Admin", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "RevenueDetailViewController")
                as? RevenueDetailViewController else { return }
        presentInNav(vc)
    }

    @objc private func openOrders() {
        let sb = UIStoryboard(name: "Admin", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "OrdersViewController")
                as? OrdersViewController else { return }
        presentInNav(vc)
    }

    /// Dashboard không có NavigationController bao ngoài → bọc sub-VC trong NavController rồi present fullscreen
    private func presentInNav(_ vc: UIViewController) {
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.isHidden = true   // Sub-screen tự vẽ header trong storyboard
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    // MARK: - Profile

    private func addProfileTapButton() {
        let btn = UIButton(type: .system)
        btn.frame = CGRect(x: view.bounds.width - 70, y: 108, width: 70, height: 70)
        btn.autoresizingMask = [.flexibleLeftMargin]
        btn.addTarget(self, action: #selector(openAdminProfile), for: .touchUpInside)
        view.addSubview(btn)
    }

    @objc private func openAdminProfile() {
        let sb = UIStoryboard(name: "Admin", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "AdminProfileVC")
                as? AdminProfileViewController else { return }
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle   = .coverVertical
        present(vc, animated: true)
    }

    // MARK: - Helpers

    private func formatPrice(_ price: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: price)) ?? "\(Int(price))") + "đ"
    }
}
