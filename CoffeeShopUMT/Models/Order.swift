import Foundation

struct OrderItem: Codable {
    let menuItemId: String
    var quantity: Int
    var note: String?
}

struct Order: Codable {
    let id: String
    var tableId: String
    var items: [OrderItem]
    var status: String
    var totalAmount: Double
    var createdAt: Date
}
