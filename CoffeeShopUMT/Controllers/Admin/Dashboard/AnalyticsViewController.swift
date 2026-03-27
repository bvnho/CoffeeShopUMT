import UIKit

final class AnalyticsViewModel {
    // TODO: Add analytics logic
}

final class AnalyticsViewController: UIViewController {
    private let viewModel = AnalyticsViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        addProfileTapButton()
    }

    /// Phủ UIButton trong suốt lên icon Person góc trên phải
    /// (id="ckL-26-4Nn" trong storyboard: trailing=26, width=29, height≈23).
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

    // Nối nút "Overview" trên giao diện vào hàm này
    @IBAction func goToOverviewTapped(_ sender: UIButton) {
        // Để quay lại Dashboard, ta chỉ cần đóng (Pop) màn hình Analytics hiện tại lại.
        // animated: false để chuyển cảnh tức thì.
        self.navigationController?.popViewController(animated: false)
    }
}

