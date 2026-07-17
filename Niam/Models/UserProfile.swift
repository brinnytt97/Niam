import Foundation
import SwiftData

@Model
final class UserProfile {
    var heightCm: Double
    var weightKg: Double
    var age: Int
    var biologicalSex: BiologicalSex
    var activityLevel: ActivityLevel
    var goal: DietGoal

    init(
        heightCm: Double = 170,
        weightKg: Double = 70,
        age: Int = 25,
        biologicalSex: BiologicalSex = .male,
        activityLevel: ActivityLevel = .moderate,
        goal: DietGoal = .maintain
    ) {
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.age = age
        self.biologicalSex = biologicalSex
        self.activityLevel = activityLevel
        self.goal = goal
    }

    /// Basal Metabolic Rate (Mifflin-St Jeor)
    var bmr: Double {
        switch biologicalSex {
        case .male:
            10 * weightKg + 6.25 * heightCm - 5 * Double(age) + 5
        case .female:
            10 * weightKg + 6.25 * heightCm - 5 * Double(age) - 161
        }
    }

    /// Total Daily Energy Expenditure
    var tdee: Double {
        bmr * activityLevel.multiplier
    }

    /// Daily calorie target adjusted for goal
    var dailyCalorieTarget: Int {
        Int(tdee + goal.calorieAdjustment)
    }
}

enum BiologicalSex: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "Sedentary"
    case light = "Lightly Active"
    case moderate = "Moderately Active"
    case active = "Very Active"
    case extreme = "Extremely Active"

    var multiplier: Double {
        switch self {
        case .sedentary: 1.2
        case .light: 1.375
        case .moderate: 1.55
        case .active: 1.725
        case .extreme: 1.9
        }
    }
}

enum DietGoal: String, Codable, CaseIterable {
    case lose = "Lose Weight"
    case maintain = "Maintain"
    case gain = "Gain Weight"

    var calorieAdjustment: Double {
        switch self {
        case .lose: -500
        case .maintain: 0
        case .gain: 500
        }
    }
}
