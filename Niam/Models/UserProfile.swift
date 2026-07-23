import Foundation
import SwiftData

@Model
final class UserProfile {
    var displayName: String
    var heightCm: Double?
    var weightKg: Double?
    var birthYear: Int?
    var biologicalSex: BiologicalSex?
    var activityLevel: ActivityLevel?
    var goal: DietGoal?
    var customCalorieTarget: Int?
    var avatarData: Data?
    var avatarEmoji: String?

    init(
        displayName: String = "there",
        heightCm: Double? = nil,
        weightKg: Double? = nil,
        birthYear: Int? = nil,
        biologicalSex: BiologicalSex? = nil,
        activityLevel: ActivityLevel? = nil,
        goal: DietGoal? = nil,
        customCalorieTarget: Int? = nil
    ) {
        self.displayName = displayName
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.birthYear = birthYear
        self.biologicalSex = biologicalSex
        self.activityLevel = activityLevel
        self.goal = goal
        self.customCalorieTarget = customCalorieTarget
    }

    var age: Int? {
        birthYear.map { Calendar.current.component(.year, from: .now) - $0 }
    }

    /// Basal Metabolic Rate (Mifflin-St Jeor)
    var bmr: Double {
        guard let w = weightKg, let h = heightCm, let a = age, let sex = biologicalSex else { return 1800 }
        switch sex {
        case .male, .nonBinary, .preferNotToSay:
            return 10 * w + 6.25 * h - 5 * Double(a) + 5
        case .female:
            return 10 * w + 6.25 * h - 5 * Double(a) - 161
        }
    }

    /// Total Daily Energy Expenditure
    var tdee: Double {
        bmr * (activityLevel?.multiplier ?? 1.55)
    }

    /// Daily calorie target adjusted for goal, or custom override
    var dailyCalorieTarget: Int {
        customCalorieTarget ?? Int(tdee + (goal?.calorieAdjustment ?? 0))
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
