import Foundation
import SwiftData

@Model
final class WaterIntake {
    var date: Date
    var count: Int
    var target: Int

    init(date: Date = .now, count: Int = 0, target: Int = 8) {
        self.date = Calendar.current.startOfDay(for: date)
        self.count = count
        self.target = target
    }
}

// MARK: - Drink Types

enum DrinkType: String, CaseIterable, Codable {
    case water = "Water"
    case coffee = "Coffee"
    case tea = "Tea"
    case juice = "Juice"
    case milk = "Milk"
    case soda = "Soda"
    case other = "Other"

    var emoji: String {
        switch self {
        case .water: "💧"
        case .coffee: "☕️"
        case .tea: "🍵"
        case .juice: "🍊"
        case .milk: "🥛"
        case .soda: "🥤"
        case .other: "🫗"
        }
    }

    /// Caffeine in mg per standard serving
    var caffeineMg: Int {
        switch self {
        case .water: 0
        case .coffee: 95
        case .tea: 47
        case .juice: 0
        case .milk: 0
        case .soda: 34
        case .other: 0
        }
    }

    /// Whether this counts as a water glass
    var countsAsWater: Bool {
        switch self {
        case .water, .juice, .milk, .other: true
        case .coffee, .tea, .soda: false
        }
    }
}

@Model
final class DrinkEntry {
    var date: Date
    var drinkType: String   // DrinkType.rawValue
    var volumeMl: Int       // 250 ml default

    var type: DrinkType { DrinkType(rawValue: drinkType) ?? .water }

    init(drinkType: DrinkType = .water, volumeMl: Int = 250) {
        self.date = .now
        self.drinkType = drinkType.rawValue
        self.volumeMl = volumeMl
    }
}
