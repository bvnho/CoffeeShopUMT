import UIKit

final class LoginViewModel {
    // TODO: Add authentication logic
}

final class LoginViewController: UIViewController {
    @IBOutlet private weak var usernameTextField: UITextField?
    @IBOutlet private weak var passwordTextField: UITextField?
    @IBOutlet private weak var signInButton: UIButton?

    private let viewModel = LoginViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#221910")
        navigationController?.setNavigationBarHidden(true, animated: false)

        usernameTextField?.textColor = .white
        usernameTextField?.backgroundColor = UIColor(hex: "#120E0A")
        usernameTextField?.borderStyle = .roundedRect

        passwordTextField?.textColor = .white
        passwordTextField?.backgroundColor = UIColor(hex: "#120E0A")
        passwordTextField?.borderStyle = .roundedRect

        signInButton?.backgroundColor = UIColor(hex: "#BD660F")
        signInButton?.setTitleColor(.white, for: .normal)
        signInButton?.layer.cornerRadius = 10
    }

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func handleKeyboardWillShow(_ notification: Notification) {
        guard view.frame.origin.y == 0 else { return }
        view.frame.origin.y = -80
    }

    @objc private func handleKeyboardWillHide(_ notification: Notification) {
        view.frame.origin.y = 0
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
