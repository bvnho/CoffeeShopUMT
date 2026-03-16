import UIKit

final class AnalyticsViewModel {
    // TODO: Add analytics logic
}

final class AnalyticsViewController: UIViewController {
    private let viewModel = AnalyticsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // Nối nút "Overview" trên giao diện vào hàm này
    @IBAction func goToOverviewTapped(_ sender: UIButton) {
        // Để quay lại Dashboard, ta chỉ cần đóng (Pop) màn hình Analytics hiện tại lại.
        // animated: false để chuyển cảnh tức thì.
        self.navigationController?.popViewController(animated: false)
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
