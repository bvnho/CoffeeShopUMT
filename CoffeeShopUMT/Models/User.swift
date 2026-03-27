import Foundation

struct User: Codable {
    let id: String
    var fullName: String
    var email: String
    var role: String
    var salary: Double?
    var isActive: Bool
    var profileImageURL: String?  // URL hoặc base64 data URI
}
