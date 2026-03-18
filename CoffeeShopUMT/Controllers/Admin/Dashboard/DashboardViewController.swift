import UIKit

final class DashboardViewModel {
    // TODO: Add dashboard overview logic
    
    
}

final class DashboardViewController: UIViewController {
    private let viewModel = DashboardViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Giao diện đã được vẽ trên Storyboard nên ta không cần gọi setupUI() đổi màu nền ở đây nữa
    }
    
    
    
    
    @IBAction func goToAnalyticsTapped(_ sender: UIButton) {
        // Đã sửa lại tên ID thành "AnalyticsViewController" cho khớp với cài đặt của bạn
        if let storyboard = self.storyboard,
           let analyticsVC = storyboard.instantiateViewController(withIdentifier: "AnalyticsViewController") as? AnalyticsViewController {
            
            self.navigationController?.pushViewController(analyticsVC, animated: false)
        }
    }
}
