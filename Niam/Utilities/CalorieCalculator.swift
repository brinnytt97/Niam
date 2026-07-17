import Foundation

enum CalorieCalculator {
    /// Calculate remaining calories for the day
    static func remainingCalories(
        target: Int,
        consumed: [MealRecord],
        for date: Date = .now
    ) -> Int {
        let todayRecords = consumed.filter {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
        let totalConsumed = todayRecords.reduce(0) { $0 + $1.calories }
        return max(0, target - totalConsumed)
    }

    /// Total calories consumed today
    static func totalCalories(
        consumed: [MealRecord],
        for date: Date = .now
    ) -> Int {
        consumed
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .reduce(0) { $0 + $1.calories }
    }

    /// Macronutrient totals for a given day
    static func macroTotals(
        consumed: [MealRecord],
        for date: Date = .now
    ) -> (protein: Double, carbs: Double, fat: Double) {
        let today = consumed.filter {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
        return (
            protein: today.reduce(0) { $0 + $1.protein },
            carbs: today.reduce(0) { $0 + $1.carbs },
            fat: today.reduce(0) { $0 + $1.fat }
        )
    }
}
