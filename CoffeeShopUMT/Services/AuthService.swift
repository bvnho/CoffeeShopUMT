import Foundation

final class AuthService {
    static let shared = AuthService()

    private init() {}

    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }

    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }
}
