import Foundation

struct MenuItem: Codable {
    let id: String
    var name: String
    var price: Double
    var imageURL: String?
    var category: String
    var isAvailable: Bool
}
