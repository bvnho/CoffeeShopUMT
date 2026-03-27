import Foundation

struct Table: Codable {
    let id: String
    var code: String
    var status: String
    var currentOrderId: String?
}

enum TableType {
    case dineIn
    case takeaway
}

struct TableOption {
    let id: String
    let name: String
    let type: TableType
    var isOccupied: Bool
}

extension TableOption {
    static func hardcodedOptions() -> [TableOption] {
        var options: [TableOption] = (1...9).map {
            TableOption(id: "table_\($0)", name: "Bàn \($0)", type: .dineIn, isOccupied: false)
        }

        options.append(
            TableOption(id: "takeaway", name: "Khách mua mang về", type: .takeaway, isOccupied: false)
        )

        return options
    }
}

final class TableStateStore {
    static let shared = TableStateStore()

    private var options: [TableOption] = TableOption.hardcodedOptions()

    private init() {}

    func getOptions() -> [TableOption] {
        options.map { option in
            guard option.type == .takeaway else { return option }
            var normalized = option
            normalized.isOccupied = false
            return normalized
        }
    }

    @discardableResult
    func selectOption(id: String) -> TableOption? {
        guard let index = options.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        if options[index].type == .dineIn {
            options[index].isOccupied = true
        } else {
            options[index].isOccupied = false
        }

        return options[index]
    }

    func markTableEmpty(id: String) {
        guard let index = options.firstIndex(where: { $0.id == id }) else { return }
        options[index].isOccupied = false
    }
}
