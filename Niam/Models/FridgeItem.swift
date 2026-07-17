import Foundation
import SwiftData

@Model
final class FridgeItem {
    var name: String
    var quantity: Double
    var unit: FoodUnit
    var category: FoodCategory
    var expirationDate: Date?
    var addedDate: Date
    var notes: String

    init(
        name: String,
        quantity: Double = 1,
        unit: FoodUnit = .piece,
        category: FoodCategory = .other,
        expirationDate: Date? = nil,
        notes: String = ""
    ) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.expirationDate = expirationDate
        self.addedDate = .now
        self.notes = notes
    }

    var isExpired: Bool {
        guard let expirationDate else { return false }
        return expirationDate < .now
    }

    var isExpiringSoon: Bool {
        guard let expirationDate else { return false }
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: .now)!
        return expirationDate <= threeDaysFromNow && !isExpired
    }
}

enum FoodUnit: String, Codable, CaseIterable {
    case gram = "g"
    case kilogram = "kg"
    case milliliter = "ml"
    case liter = "L"
    case piece = "piece"
    case pack = "pack"
    case bottle = "bottle"
    case box = "box"
}

enum FoodCategory: String, Codable, CaseIterable {
    case vegetable = "Vegetable"
    case fruit = "Fruit"
    case meat = "Meat"
    case seafood = "Seafood"
    case dairy = "Dairy"
    case grain = "Grain"
    case condiment = "Condiment"
    case beverage = "Beverage"
    case frozen = "Frozen"
    case snack = "Snack"
    case other = "Other"
}
