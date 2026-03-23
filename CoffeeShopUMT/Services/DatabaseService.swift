import Foundation
import FirebaseFirestore

final class DatabaseService {
    static let shared = DatabaseService()
    private init() {}

    private lazy var db = Firestore.firestore()

    func fetchStaffAndAdmins(completion: @escaping (Result<[User], Error>) -> Void) {
        db.collection("Users")
            .whereField("role", in: ["Admin", "Staff"])
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let users: [User] = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    let fullName = data["fullName"] as? String ?? ""
                    let email = data["email"] as? String ?? ""
                    let role = data["role"] as? String ?? "Staff"
                    let isActive = data["isActive"] as? Bool ?? true

                    return User(
                        id: document.documentID,
                        fullName: fullName,
                        email: email,
                        role: role,
                        isActive: isActive
                    )
                } ?? []

                completion(.success(users))
            }
    }

    func toggleUserStatus(userId: String, isActive: Bool, completion: @escaping (Error?) -> Void) {
        db.collection("Users")
            .document(userId)
            .updateData(["isActive": isActive], completion: completion)
    }

    func updateUserRole(userId: String, role: String, completion: @escaping (Error?) -> Void) {
        db.collection("Users")
            .document(userId)
            .updateData(["role": role], completion: completion)
    }

    func createNewUserDocument(
        uid: String,
        fullName: String,
        email: String,
        role: String,
        isActive: Bool,
        completion: @escaping (Error?) -> Void
    ) {
        let payload: [String: Any] = [
            "fullName": fullName,
            "email": email,
            "role": role,
            "isActive": isActive
        ]

        db.collection("Users")
            .document(uid)
            .setData(payload, completion: completion)
    }
}
