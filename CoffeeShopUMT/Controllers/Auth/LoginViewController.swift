import UIKit

enum UserRole {
    case admin
    case staff
}

struct DemoAccount {
    let username: String
    let password: String
    let role: UserRole
}

final class LoginViewModel {
    private let accounts: [DemoAccount] = [
        DemoAccount(username: "admin", password: "123456", role: .admin),
        DemoAccount(username: "staff", password: "123456", role: .staff)
    ]

    func authenticate(username: String, password: String) -> UserRole? {
        let normalizedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        return accounts.first {
            $0.username.lowercased() == normalizedUsername && $0.password == normalizedPassword
        }?.role
    }
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

        signInButton?.addTarget(self, action: #selector(handleSignInTapped), for: .touchUpInside)
        usernameTextField?.returnKeyType = .next
        passwordTextField?.returnKeyType = .go
        usernameTextField?.addTarget(self, action: #selector(handleUsernameReturn), for: .editingDidEndOnExit)
        passwordTextField?.addTarget(self, action: #selector(handlePasswordReturn), for: .editingDidEndOnExit)
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

    @objc private func handleSignInTapped() {
        let username = usernameTextField?.text ?? ""
        let password = passwordTextField?.text ?? ""

        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Thiếu thông tin", message: "Vui lòng nhập tài khoản và mật khẩu.")
            return
        }

        guard let role = viewModel.authenticate(username: username, password: password) else {
            showAlert(title: "Đăng nhập thất bại", message: "Sai tài khoản hoặc mật khẩu.")
            return
        }

        navigateToMainScreen(for: role)
    }

    @objc private func handleUsernameReturn() {
        passwordTextField?.becomeFirstResponder()
    }

    @objc private func handlePasswordReturn() {
        passwordTextField?.resignFirstResponder()
        handleSignInTapped()
    }

    private func navigateToMainScreen(for role: UserRole) {
        let storyboardName = role == .admin ? "Admin" : "Staff"
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)

        guard let destination = storyboard.instantiateInitialViewController() else {
            showAlert(title: "Lỗi", message: "Không mở được màn hình \(storyboardName).")
            return
        }

        if let windowScene = view.window?.windowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            window.rootViewController = destination
            UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve, animations: nil)
            window.makeKeyAndVisible()
            return
        }

        destination.modalPresentationStyle = .fullScreen
        present(destination, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
