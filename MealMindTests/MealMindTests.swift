import Testing
@testable import MealMind

@Suite("UserProfile TDEE Calculation")
struct UserProfileTests {
    @Test("BMR calculation for male")
    func bmrMale() {
        let profile = UserProfile(heightCm: 175, weightKg: 75, age: 25, biologicalSex: .male)
        // Mifflin-St Jeor: 10*75 + 6.25*175 - 5*25 + 5 = 750 + 1093.75 - 125 + 5 = 1723.75
        #expect(abs(profile.bmr - 1723.75) < 0.01)
    }

    @Test("BMR calculation for female")
    func bmrFemale() {
        let profile = UserProfile(heightCm: 165, weightKg: 60, age: 30, biologicalSex: .female)
        // 10*60 + 6.25*165 - 5*30 - 161 = 600 + 1031.25 - 150 - 161 = 1320.25
        #expect(abs(profile.bmr - 1320.25) < 0.01)
    }

    @Test("Daily calorie target with weight loss goal")
    func calorieTargetLose() {
        let profile = UserProfile(
            heightCm: 175, weightKg: 75, age: 25,
            biologicalSex: .male, activityLevel: .moderate, goal: .lose
        )
        // TDEE = 1723.75 * 1.55 = 2671.8125, target = 2671.8125 - 500 = 2171
        #expect(profile.dailyCalorieTarget == 2171)
    }
}

@Suite("CalorieCalculator")
struct CalorieCalculatorTests {
    @Test("Remaining calories calculation")
    func remainingCalories() {
        let records = [
            MealRecord(name: "Breakfast", calories: 400),
            MealRecord(name: "Lunch", calories: 600),
        ]
        let remaining = CalorieCalculator.remainingCalories(target: 2000, consumed: records)
        #expect(remaining == 1000)
    }

    @Test("Remaining calories never negative")
    func remainingNeverNegative() {
        let records = [MealRecord(name: "Big Meal", calories: 3000)]
        let remaining = CalorieCalculator.remainingCalories(target: 2000, consumed: records)
        #expect(remaining == 0)
    }
}
