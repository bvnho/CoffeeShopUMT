import Foundation

struct CartItem {
    let menuItem: MenuItem
    var quantity: Int
}

struct OrderItem: Codable {
    let menuItemId: String
    let name: String
    let price: Double
    var quantity: Int
    var note: String?
    var imageURL: String?
}

struct Order: Codable {
    let id: String
    var tableId: String
    var tableName: String
    var items: [OrderItem]
    var status: String
    var totalAmount: Double
    var createdAt: Date
    var updatedAt: Date?
}
