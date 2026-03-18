import Foundation

final class DatabaseService {
    static let shared = DatabaseService()

    private init() {}

    func fetchMenuItems(completion: @escaping (Result<[MenuItem], Error>) -> Void) {
        completion(.success([]))
    }

    func fetchTables(completion: @escaping (Result<[Table], Error>) -> Void) {
        completion(.success([]))
    }

    func fetchOrders(completion: @escaping (Result<[Order], Error>) -> Void) {
        completion(.success([]))
    }
}
