import Foundation
import FirebaseAuth

final class AuthService {
    static let shared = AuthService()
    private init() {}

    // MARK: - Current User (UserDefaults cache)

    /// Người dùng đang đăng nhập. Đặt sau khi đăng nhập thành công.
    var currentUser: User? {
        get { loadCurrentUser() }
        set { newValue == nil ? clearCurrentUser() : saveCurrentUser(newValue!) }
    }

    func saveCurrentUser(_ user: User) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        UserDefaults.standard.set(data, forKey: "currentUser")
    }

    private func loadCurrentUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: "currentUser") else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    private func clearCurrentUser() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }

    // MARK: - Login (stub — LoginViewController dùng Firebase trực tiếp)

    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }

    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }

    // MARK: - Change Password

    /// Đổi mật khẩu qua Firebase Auth.
    /// Lưu ý: Firebase yêu cầu re-authentication nếu đăng nhập đã lâu.
    func changePassword(
        newPassword: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let firebaseUser = Auth.auth().currentUser else {
            let err = NSError(
                domain: "AuthService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."]
            )
            completion(.failure(err))
            return
        }
        firebaseUser.updatePassword(to: newPassword) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Logout

    /// Xóa session và chuyển root VC về Auth storyboard.
    func logout(from viewController: UIViewController) {
        // 1. Firebase sign out
        try? Auth.auth().signOut()

        // 2. Xóa dữ liệu cục bộ
        clearCurrentUser()
        UserDefaults.standard.removeObject(forKey: "authToken")

        // 3. Chuyển về màn hình Auth (giống pattern trong LoginViewController)
        let authStoryboard = UIStoryboard(name: "Auth", bundle: nil)
        guard let authRoot = authStoryboard.instantiateInitialViewController() else { return }

        if let windowScene = viewController.view.window?.windowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            window.rootViewController = authRoot
            UIView.transition(
                with: window,
                duration: 0.35,
                options: .transitionCrossDissolve,
                animations: nil
            )
            window.makeKeyAndVisible()
        }
    }
}
