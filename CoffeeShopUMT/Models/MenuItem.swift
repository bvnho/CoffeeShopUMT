import Foundation
import FirebaseFirestore

struct MenuItem: Codable {
    @DocumentID var id: String?
    var name: String
    var category: String
    var price: Double
    var descriptionText: String
    var isAvailable: Bool
    var imageURL: String?
}
