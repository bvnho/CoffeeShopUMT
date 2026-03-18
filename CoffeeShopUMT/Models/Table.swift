import Foundation

struct Table: Codable {
    let id: String
    var code: String
    var status: String
    var currentOrderId: String?
}
