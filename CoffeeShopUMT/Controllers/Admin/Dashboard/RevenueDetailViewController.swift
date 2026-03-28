import UIKit
import FirebaseFirestore

final class RevenueDetailViewController: UIViewController {

    // MARK: - Period

    private enum Period { case day, month, year }
    private var period: Period = .day

    // MARK: - Data

    private var paidOrders: [Order] = []
    private var ordersListener: ListenerRegistration?

    // MARK: - Located views

    private var filterSegment: UISegmentedControl?
    private var totalValueLabel: UILabel?
    private var subtitleLabel: UILabel?
    private var ordersCountLabel: UILabel?
    private var avgTicketLabel: UILabel?
    private var transactionsTableView: UITableView?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        locateStoryboardViews()
        wireBackButton()
        addExportButton()
        startListening()
    }

    deinit {
        ordersListener?.remove()
    }

    // MARK: - Locate storyboard views

    private func locateStoryboardViews() {
        filterSegment = view.findSubviews(of: UISegmentedControl.self).first
        filterSegment?.addTarget(self, action: #selector(periodChanged), for: .valueChanged)
        filterSegment?.setTitleTextAttributes(
            [.foregroundColor: UIColor.appTextSecondary], for: .normal)
        filterSegment?.setTitleTextAttributes(
            [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 14, weight: .semibold)],
            for: .selected)

        let allLabels = view.findSubviews(of: UILabel.self)
        totalValueLabel  = allLabels.first { $0.text == "2.000.000 VND" }
        subtitleLabel    = allLabels.first { $0.text == "TOTAL REVENUE TODAY" }
        ordersCountLabel = allLabels.first { $0.text == "84" }
        avgTicketLabel   = allLabels.first { $0.text == "24.000 VND" }

        transactionsTableView = view.findSubviews(of: UITableView.self).first
        transactionsTableView?.dataSource      = self
        transactionsTableView?.delegate        = self
        transactionsTableView?.backgroundColor = .clear
        transactionsTableView?.separatorColor  = UIColor.white.withAlphaComponent(0.12)
        transactionsTableView?.rowHeight       = 60
        transactionsTableView?.register(UITableViewCell.self, forCellReuseIdentifier: "TxnCell")
    }

    // MARK: - Back & Export buttons

    private func wireBackButton() {
        view.findSubviews(of: UIButton.self)
            .first { $0.title(for: .normal)?.contains("Back") == true }?
            .addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    private func addExportButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Export PDF",
            style: .plain,
            target: self,
            action: #selector(exportPDF)
        )
        navigationItem.rightBarButtonItem?.tintColor = .appAccent
    }

    @objc private func backTapped() {
        if navigationController?.viewControllers.first === self {
            navigationController?.dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - Period switching

    @objc private func periodChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: period = .day
        case 1: period = .month
        default: period = .year
        }
        subtitleLabel?.text = periodSubtitleText()
        ordersListener?.remove()
        startListening()
    }

    // MARK: - Firestore listener

    private func startListening() {
        let (start, end) = dateRange(for: period)
        ordersListener = DatabaseService.shared.listenToOrders(from: start, to: end) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let orders) = result {
                    self?.paidOrders = orders
                    self?.updateUI()
                }
            }
        }
    }

    // MARK: - Update UI

    private func updateUI() {
        let revenue = paidOrders.reduce(0.0) { $0 + $1.totalAmount }
        let count   = paidOrders.count
        let avg     = count > 0 ? revenue / Double(count) : 0.0

        totalValueLabel?.text  = formatPrice(revenue)
        ordersCountLabel?.text = "\(count)"
        avgTicketLabel?.text   = formatPrice(avg)
        transactionsTableView?.reloadData()
    }

    // MARK: - Navigation to detail

    private func pushOrderDetail(_ order: Order) {
        let sb = UIStoryboard(name: "Admin", bundle: nil)
        guard let vc = sb.instantiateViewController(withIdentifier: "OrderDetailViewController")
                as? OrderDetailViewController else { return }
        vc.order = order
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - PDF Export

    @objc private func exportPDF() {
        let pdfData = buildPDF()
        let fileName = "Revenue_\(periodFileLabel()).pdf"
        let tmpURL   = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try pdfData.write(to: tmpURL)
        } catch {
            showAlert("Không thể tạo file PDF.")
            return
        }
        let ac = UIActivityViewController(activityItems: [tmpURL], applicationActivities: nil)
        ac.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(ac, animated: true)
    }

    private func buildPDF() -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)  // A4
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            ctx.beginPage()
            let cg = ctx.cgContext

            // Header
            draw("Báo cáo doanh thu", at: CGPoint(x: 40, y: 40),
                 font: .boldSystemFont(ofSize: 22), color: .black)
            draw(periodSubtitleText(), at: CGPoint(x: 40, y: 70),
                 font: .systemFont(ofSize: 14), color: .darkGray)

            // Stats
            let revenue = paidOrders.reduce(0.0) { $0 + $1.totalAmount }
            let avg     = paidOrders.isEmpty ? 0.0 : revenue / Double(paidOrders.count)
            let stats   = "Tổng doanh thu: \(formatPrice(revenue))   " +
                          "Số đơn: \(paidOrders.count)   " +
                          "TB/đơn: \(formatPrice(avg))   Hoàn tiền: 0đ"
            draw(stats, at: CGPoint(x: 40, y: 100),
                 font: .systemFont(ofSize: 11), color: .darkGray)

            // Separator
            cg.setStrokeColor(UIColor.lightGray.cgColor)
            cg.setLineWidth(0.5)
            cg.move(to: CGPoint(x: 40, y: 122))
            cg.addLine(to: CGPoint(x: 555, y: 122))
            cg.strokePath()

            // Column headers
            draw("Mã đơn",    at: CGPoint(x: 40,  y: 132), font: .boldSystemFont(ofSize: 10), color: .gray)
            draw("Bàn",       at: CGPoint(x: 160, y: 132), font: .boldSystemFont(ofSize: 10), color: .gray)
            draw("Thời gian", at: CGPoint(x: 260, y: 132), font: .boldSystemFont(ofSize: 10), color: .gray)
            draw("Tổng tiền", at: CGPoint(x: 440, y: 132), font: .boldSystemFont(ofSize: 10), color: .gray)

            // Rows
            var y: CGFloat = 152
            let lineH: CGFloat = 22
            let rowFont = UIFont.systemFont(ofSize: 11)

            for order in paidOrders {
                if y + lineH > pageRect.height - 40 {
                    ctx.beginPage()
                    y = 40
                }
                draw("#\(order.id.prefix(8).uppercased())", at: CGPoint(x: 40,  y: y), font: rowFont, color: .black)
                draw(order.tableName,                        at: CGPoint(x: 160, y: y), font: rowFont, color: .black)
                draw(formatDateTime(order.paidAt ?? order.createdAt),
                                                             at: CGPoint(x: 260, y: y), font: rowFont, color: .black)
                draw(formatPrice(order.totalAmount),         at: CGPoint(x: 440, y: y), font: rowFont, color: .black)
                y += lineH
            }
        }
    }

    /// Helper nhỏ gọi draw string vào CGContext
    private func draw(_ text: String, at point: CGPoint, font: UIFont, color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        text.draw(at: point, withAttributes: attrs)
    }

    // MARK: - Date range helpers

    private func dateRange(for period: Period) -> (Date, Date) {
        let cal = Calendar.current
        let now = Date()
        switch period {
        case .day:
            let start = cal.startOfDay(for: now)
            let end   = cal.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
        case .month:
            let comps = cal.dateComponents([.year, .month], from: now)
            let start = cal.date(from: comps)!
            let end   = cal.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        case .year:
            let comps = cal.dateComponents([.year], from: now)
            let start = cal.date(from: comps)!
            let end   = cal.date(byAdding: .year, value: 1, to: start)!
            return (start, end)
        }
    }

    private func periodSubtitleText() -> String {
        switch period {
        case .day:   return "TỔNG DOANH THU HÔM NAY"
        case .month: return "TỔNG DOANH THU THÁNG NÀY"
        case .year:  return "TỔNG DOANH THU NĂM NAY"
        }
    }

    private func periodFileLabel() -> String {
        let f = DateFormatter()
        switch period {
        case .day:   f.dateFormat = "dd-MM-yyyy"
        case .month: f.dateFormat = "MM-yyyy"
        case .year:  f.dateFormat = "yyyy"
        }
        return f.string(from: Date())
    }

    // MARK: - Helpers

    private func formatPrice(_ price: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return (f.string(from: NSNumber(value: price)) ?? "\(Int(price))") + "đ"
    }

    private func formatDateTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm • dd/MM/yyyy"
        return f.string(from: date)
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Thông báo", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource / Delegate

extension RevenueDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = paidOrders.count
        tableView.backgroundView = count == 0 ? emptyLabel() : nil
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell  = tableView.dequeueReusableCell(withIdentifier: "TxnCell", for: indexPath)
        let order = paidOrders[indexPath.row]

        var config = UIListContentConfiguration.subtitleCell()
        config.text                          = "#\(order.id.prefix(8).uppercased())"
        config.secondaryText                 = "\(order.tableName) • \(formatDateTime(order.paidAt ?? order.createdAt))"
        config.textProperties.color          = .appAccent
        config.secondaryTextProperties.color = .appTextSecondary
        config.secondaryTextProperties.font  = .systemFont(ofSize: 12)

        let priceLabel = UILabel()
        priceLabel.text      = formatPrice(order.totalAmount)
        priceLabel.textColor = .appTextPrimary
        priceLabel.font      = .systemFont(ofSize: 14, weight: .semibold)
        priceLabel.sizeToFit()

        cell.contentConfiguration = config
        cell.accessoryView        = priceLabel
        cell.backgroundColor      = .clear
        cell.selectionStyle       = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        pushOrderDetail(paidOrders[indexPath.row])
    }

    private func emptyLabel() -> UILabel {
        let lbl = UILabel()
        lbl.text          = "Chưa có giao dịch nào"
        lbl.textColor     = .appTextSecondary
        lbl.font          = .systemFont(ofSize: 16)
        lbl.textAlignment = .center
        return lbl
    }
}
