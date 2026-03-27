import UIKit

final class DashboardViewModel {
    // TODO: Add dashboard overview logic
}

final class DashboardViewController: UIViewController {
    private let viewModel = DashboardViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        addProfileTapButton()
    }

    /// Phủ một UIButton trong suốt lên vùng icon Person ở góc trên phải
    /// (cùng vị trí với imageView id="0PV-c7-a5A" trong storyboard: x≈338, y≈119, w≈29, h≈60).
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
}
