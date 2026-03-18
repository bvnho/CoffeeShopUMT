import Foundation

struct User: Codable {
    let id: String
    var name: String
    var role: String
    var salary: Double?
    var isActive: Bool
}
