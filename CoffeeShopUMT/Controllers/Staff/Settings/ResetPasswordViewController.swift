import UIKit

final class ResetPasswordViewController: UIViewController {

    // MARK: - IBOutlets (connected in Staff.storyboard)

    @IBOutlet private weak var newPasswordTextField: UITextField!
    @IBOutlet private weak var confirmPasswordTextField: UITextField!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var confirmButton: UIButton!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextFields()
        cancelButton?.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        confirmButton?.addTarget(self, action: #selector(handleConfirm), for: .touchUpInside)

        // Tap vùng tối ngoài dialog → đóng màn hình
        let backgroundTap = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        view.addGestureRecognizer(backgroundTap)
    }

    // MARK: - Setup

    private func setupTextFields() {
        newPasswordTextField.text = ""
        confirmPasswordTextField.text = ""
        newPasswordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true
        newPasswordTextField.placeholder = "Tối thiểu 6 ký tự"
        confirmPasswordTextField.placeholder = "Nhập lại mật khẩu"
        newPasswordTextField.returnKeyType = .next
        confirmPasswordTextField.returnKeyType = .done
        newPasswordTextField.addTarget(self, action: #selector(newPasswordReturnTapped), for: .editingDidEndOnExit)
        confirmPasswordTextField.addTarget(self, action: #selector(handleConfirm), for: .editingDidEndOnExit)
    }

    // MARK: - Background dismiss

    @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: view)
        // Dialog là subview đầu tiên của view; chỉ dismiss khi tap ra ngoài dialog
        guard let dialog = view.subviews.first else { return }
        if !dialog.frame.contains(point) {
            dismiss(animated: true)
        }
    }

    // MARK: - Actions

    @objc private func newPasswordReturnTapped() {
        confirmPasswordTextField.becomeFirstResponder()
    }

    @objc private func handleCancel() {
        dismiss(animated: true)
    }

    @objc private func handleConfirm() {
        view.endEditing(true)

        let newPwd     = newPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let confirmPwd = confirmPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // --- Validate ---
        guard !newPwd.isEmpty else {
            showAlert(title: "Thiếu thông tin", message: "Vui lòng nhập mật khẩu mới.")
            return
        }
        guard newPwd.count >= 6 else {
            showAlert(title: "Mật khẩu quá ngắn", message: "Mật khẩu phải có ít nhất 6 ký tự.")
            return
        }
        guard newPwd == confirmPwd else {
            showAlert(title: "Mật khẩu không khớp", message: "Hai mật khẩu không giống nhau. Vui lòng nhập lại.")
            confirmPasswordTextField.text = ""
            confirmPasswordTextField.becomeFirstResponder()
            return
        }

        // --- Gọi API ---
        setLoading(true)
        AuthService.shared.changePassword(newPassword: newPwd) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.setLoading(false)
                switch result {
                case .success:
                    self.showSuccessAndDismiss()
                case .failure(let error):
                    self.showAlert(
                        title: "Đổi mật khẩu thất bại",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    private func setLoading(_ isLoading: Bool) {
        confirmButton.isEnabled = !isLoading
        cancelButton.isEnabled  = !isLoading
        confirmButton.setTitle(isLoading ? "Đang xử lý..." : "Xác nhận", for: .normal)
    }

    private func showSuccessAndDismiss() {
        let alert = UIAlertController(
            title: "Thành công",
            message: "Mật khẩu đã được cập nhật.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
