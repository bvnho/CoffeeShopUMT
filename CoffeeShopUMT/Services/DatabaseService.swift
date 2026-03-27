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

    func saveOrder(
        tableId: String,
        tableName: String,
        items: [OrderItem],
        totalAmount: Double,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let itemsData: [[String: Any]] = items.map { item in
            var d: [String: Any] = [
                "menuItemId": item.menuItemId,
                "name": item.name,
                "price": item.price,
                "quantity": item.quantity
            ]
            if let note = item.note { d["note"] = note }
            if let imageURL = item.imageURL { d["imageURL"] = imageURL }
            return d
        }
        let payload: [String: Any] = [
            "tableId": tableId,
            "tableName": tableName,
            "status": "pending",
            "totalAmount": totalAmount,
            "createdAt": Timestamp(date: Date()),
            "items": itemsData
        ]
        db.collection("Orders").addDocument(data: payload) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func fetchMenuItems(completion: @escaping (Result<[MenuItem], Error>) -> Void) {
        db.collection("MenuItems")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let items: [MenuItem] = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    guard let name = data["name"] as? String,
                          let category = data["category"] as? String,
                          let descriptionText = data["descriptionText"] as? String,
                          let isAvailable = data["isAvailable"] as? Bool else {
                        return nil
                    }

                    let rawPrice = data["price"]
                    let priceValue: Double

                    if let price = rawPrice as? Double {
                        priceValue = price
                    } else if let price = rawPrice as? Int {
                        priceValue = Double(price)
                    } else {
                        priceValue = 0
                    }

                    return MenuItem(
                        id: document.documentID,
                        name: name,
                        category: category,
                        price: priceValue,
                        descriptionText: descriptionText,
                        isAvailable: isAvailable,
                        imageURL: data["imageURL"] as? String
                    )
                } ?? []

                completion(.success(items))
            }
    }
}
