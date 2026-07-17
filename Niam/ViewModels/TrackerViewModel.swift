import Foundation
import SwiftData
import Observation

@Observable
final class TrackerViewModel {
    var records: [MealRecord] = []
    var profile: UserProfile?
    var selectedDate: Date = .now

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        fetchData()
    }

    var todayRecords: [MealRecord] {
        records.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var totalCaloriesToday: Int {
        CalorieCalculator.totalCalories(consumed: records, for: selectedDate)
    }

    var remainingCalories: Int {
        guard let profile else { return 0 }
        return CalorieCalculator.remainingCalories(
            target: profile.dailyCalorieTarget,
            consumed: records,
            for: selectedDate
        )
    }

    var dailyTarget: Int {
        profile?.dailyCalorieTarget ?? 2000
    }

    var macros: (protein: Double, carbs: Double, fat: Double) {
        CalorieCalculator.macroTotals(consumed: records, for: selectedDate)
    }

    struct DailyCalorie: Identifiable {
        let id = UUID()
        let date: Date
        let calories: Int
        let target: Int

        var dayLabel: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            return formatter.string(from: date)
        }
    }

    var weeklyData: [DailyCalorie] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: selectedDate)
        let target = dailyTarget

        return (0..<7).reversed().compactMap { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
            let cals = CalorieCalculator.totalCalories(consumed: records, for: date)
            return DailyCalorie(date: date, calories: cals, target: target)
        }
    }

    func fetchData() {
        let recordDescriptor = FetchDescriptor<MealRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        records = (try? context.fetch(recordDescriptor)) ?? []

        let profileDescriptor = FetchDescriptor<UserProfile>()
        profile = (try? context.fetch(profileDescriptor))?.first
    }

    func addRecord(_ record: MealRecord) {
        context.insert(record)
        try? context.save()
        fetchData()
    }

    func deleteRecord(_ record: MealRecord) {
        context.delete(record)
        try? context.save()
        fetchData()
    }

    func saveProfile(_ profile: UserProfile) {
        // Delete old profile if exists
        if let existing = self.profile {
            context.delete(existing)
        }
        context.insert(profile)
        try? context.save()
        self.profile = profile
    }
}
