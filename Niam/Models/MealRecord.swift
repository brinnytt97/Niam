import Foundation
import SwiftData

@Model
final class MealRecord {
    var name: String
    var mealType: MealType
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var date: Date
    var notes: String

    init(
        name: String,
        mealType: MealType = .lunch,
        calories: Int = 0,
        protein: Double = 0,
        carbs: Double = 0,
        fat: Double = 0,
        date: Date = .now,
        notes: String = ""
    ) {
        self.name = name
        self.mealType = mealType
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.date = date
        self.notes = notes
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
}
