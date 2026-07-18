import Foundation
import SwiftData

@Model
final class UserProfile {
    var displayName: String
    var heightCm: Double
    var weightKg: Double
    var birthYear: Int
    var biologicalSex: BiologicalSex
    var activityLevel: ActivityLevel
    var goal: DietGoal

    init(
        displayName: String = "there",
        heightCm: Double = 170,
        weightKg: Double = 70,
        birthYear: Int = 2000,
        biologicalSex: BiologicalSex = .male,
        activityLevel: ActivityLevel = .moderate,
        goal: DietGoal = .maintain
    ) {
        self.displayName = displayName
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.birthYear = birthYear
        self.biologicalSex = biologicalSex
        self.activityLevel = activityLevel
        self.goal = goal
    }

    var age: Int {
        Calendar.current.component(.year, from: .now) - birthYear
    }

    /// Basal Metabolic Rate (Mifflin-St Jeor)
    var bmr: Double {
        switch biologicalSex {
        case .male, .nonBinary, .preferNotToSay:
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
    case female = "Female"
    case male = "Male"
    case nonBinary = "Non-binary"
    case preferNotToSay = "Prefer not to say"
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "Mostly sitting"
    case light = "Light activity"
    case moderate = "Moderate"
    case active = "Very active"

    var subtitle: String {
        switch self {
        case .sedentary: "Office work, little exercise"
        case .light: "Walking, light exercise 1-3x/week"
        case .moderate: "Exercise 3-5x/week"
        case .active: "Hard exercise 6-7x/week"
        }
    }

    var icon: String {
        switch self {
        case .sedentary: "🛋️"
        case .light: "🚶"
        case .moderate: "🏃"
        case .active: "💪"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: 1.2
        case .light: 1.375
        case .moderate: 1.55
        case .active: 1.725
        }
    }
}

enum DietGoal: String, Codable, CaseIterable {
    case lose = "Lose Weight"
    case maintain = "Maintain"
    case gain = "Gain Weight"

    var icon: String {
        switch self {
        case .lose: "↓"
        case .maintain: "—"
        case .gain: "↑"
        }
    }

    var calorieAdjustment: Double {
        switch self {
        case .lose: -500
        case .maintain: 0
        case .gain: 500
        }
    }
}
