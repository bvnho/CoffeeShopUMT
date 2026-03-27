import Foundation

enum OrderStatus: String, Codable {
    case pending   = "pending"
    case completed = "completed"
}

extension Order {
    var statusEnum: OrderStatus { OrderStatus(rawValue: status) ?? .pending }
    /// "Mang về" hoặc "Tại quán" dựa trên tableId
    var orderType: String { tableId == "takeaway" ? "Mang về" : "Tại quán" }
}

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
