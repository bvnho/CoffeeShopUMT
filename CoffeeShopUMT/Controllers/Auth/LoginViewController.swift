import UIKit
import FirebaseAuth
import FirebaseFirestore

final class LoginViewController: UIViewController {
    
    @IBOutlet private weak var usernameTextField: UITextField?
    @IBOutlet private weak var passwordTextField: UITextField?
    @IBOutlet private weak var signInButton: UIButton?

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
        usernameTextField?.placeholder = "Email hoặc Tài khoản"

        passwordTextField?.textColor = .white
        passwordTextField?.backgroundColor = UIColor(hex: "#120E0A")
        passwordTextField?.borderStyle = .roundedRect
        passwordTextField?.placeholder = "Mật khẩu"
        passwordTextField?.isSecureTextEntry = true // Che mật khẩu bằng dấu ***

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
        let email = usernameTextField?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField?.text ?? ""

        guard !email.isEmpty, !password.isEmpty else {
            showAlert(title: "Thiếu thông tin", message: "Vui lòng nhập tài khoản và mật khẩu.")
            return
        }

        signInButton?.isEnabled = false
        signInButton?.setTitle("Đang xử lý...", for: .normal)

        // CHỈ DÙNG FIREBASE ĐỂ KIỂM TRA ĐĂNG NHẬP (Cho cả Admin và Staff)
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            if let error = error {
                self.resetSignInButton()
                self.showAlert(title: "Đăng nhập thất bại", message: "Sai tài khoản hoặc mật khẩu.")
                return
            }
            
            guard let uid = authResult?.user.uid else {
                self.resetSignInButton()
                return
            }
            
            // Lấy thông tin phân quyền từ Firestore Bảng "Users"
            let db = Firestore.firestore()
            db.collection("Users").document(uid).getDocument { snapshot, error in
                self.resetSignInButton()
                
                if let error = error {
                    self.showAlert(title: "Lỗi dữ liệu", message: error.localizedDescription)
                    return
                }
                
                guard let data = snapshot?.data(),
                      let role = data["role"] as? String,
                      let isActive = data["isActive"] as? Bool else {
                    self.showAlert(title: "Truy cập bị từ chối", message: "Tài khoản của bạn chưa được thiết lập quyền hợp lệ.")
                    return
                }
                
                // Kiểm tra xem Admin có đang khóa tài khoản này không
                if !isActive {
                    self.showAlert(title: "Tài khoản bị khóa", message: "Vui lòng liên hệ quản lý để được mở khóa.")
                    try? Auth.auth().signOut()
                    return
                }
                
                // Thành công! Chuyển trang dựa theo Role
                self.navigateToMainScreen(for: role)
            }
        }
    }
    
    private func resetSignInButton() {
        signInButton?.isEnabled = true
        signInButton?.setTitle("Sign In", for: .normal)
    }

    @objc private func handleUsernameReturn() {
        passwordTextField?.becomeFirstResponder()
    }

    @objc private func handlePasswordReturn() {
        passwordTextField?.resignFirstResponder()
        handleSignInTapped()
    }

    private func navigateToMainScreen(for role: String) {
        // Ánh xạ role thành tên Storyboard
        let storyboardName = (role == "Admin") ? "Admin" : "Staff"
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)

        guard let destination = storyboard.instantiateInitialViewController() else {
            showAlert(title: "Lỗi hệ thống", message: "Không tìm thấy màn hình \(storyboardName).")
            return
        }

        // Đổi màn hình mượt mà
        if let windowScene = view.window?.windowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            window.rootViewController = destination
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
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
