import UIKit
import FirebaseAuth

final class CreateStaffViewController: UIViewController {

    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    @IBAction func grantAccountTapped(_ sender: UIButton) {
        let fullName = fullNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text ?? ""

        guard !fullName.isEmpty, !email.isEmpty, !password.isEmpty else {
            showAlert(title: "Missing Information", message: "Please fill in all fields.")
            return
        }

        // Firebase Auth automatically signs in the newly created user; a workaround may be needed later.
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }

                guard let uid = result?.user.uid else {
                    self.showAlert(title: "Error", message: "Could not get user ID.")
                    return
                }

                DatabaseService.shared.createNewUserDocument(
                    uid: uid,
                    fullName: fullName,
                    email: email,
                    role: "Staff",
                    isActive: true
                ) { dbError in
                    DispatchQueue.main.async {
                        if let dbError = dbError {
                            self.showAlert(title: "Error", message: dbError.localizedDescription)
                            return
                        }
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }

    @IBAction func cancelTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}