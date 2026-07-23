import Foundation
import HealthKit

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    @Published private(set) var exerciseCaloriesToday: Int = 0
    @Published private(set) var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published private(set) var isAvailable = HKHealthStore.isHealthDataAvailable()

    private let store = HKHealthStore()
    private let activeEnergyType = HKQuantityType(.activeEnergyBurned)

    private init() {}

    // MARK: - Authorization

    func requestAuthorizationIfNeeded() async {
        guard isAvailable else { return }
        guard authorizationStatus == .notDetermined else {
            await fetchExerciseCalories()
            return
        }
        do {
            try await store.requestAuthorization(toShare: [], read: [activeEnergyType])
            authorizationStatus = store.authorizationStatus(for: activeEnergyType)
            await fetchExerciseCalories()
        } catch {
            print("[HealthKit] auth error: \(error)")
        }
    }

    // MARK: - Fetch

    func fetchExerciseCalories(for date: Date = .now) async {
        guard isAvailable else { return }
        guard store.authorizationStatus(for: activeEnergyType) == .sharingAuthorized else { return }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        let total: Double = await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let kcal = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: kcal)
            }
            store.execute(query)
        }

        exerciseCaloriesToday = Int(total)
    }
}
