import Foundation

enum OrderStatus: String, Codable {
    case pending   = "pending"
    case ready     = "ready"      // Bếp làm xong, chờ phục vụ / thanh toán
    case completed = "completed"  // Giữ để tương thích dữ liệu cũ
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
    var paidAt: Date?             // nil = chưa thanh toán; có giá trị = đã thu tiền
}

extension Order {
    var isTakeaway: Bool { tableId == "takeaway" }
    var isPaid: Bool { paidAt != nil }
}
