import Foundation
import SwiftData
import UserNotifications
import Observation

@Observable
final class FastingViewModel {
    var currentSession: FastingSession?
    var history: [FastingSession] = []
    var targetHours: Int = 16

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        fetchData()
    }

    var isActive: Bool {
        currentSession?.isActive ?? false
    }

    var elapsedFormatted: String {
        guard let session = currentSession else { return "00:00:00" }
        return formatTimeInterval(session.elapsedSeconds)
    }

    var remainingFormatted: String {
        guard let session = currentSession else { return "00:00:00" }
        return formatTimeInterval(session.remainingSeconds)
    }

    var progress: Double {
        currentSession?.progress ?? 0
    }

    func startFasting() {
        let session = FastingSession(startTime: .now, targetHours: targetHours)
        context.insert(session)
        try? context.save()
        currentSession = session
        scheduleNotification(targetDate: session.targetEndTime, hours: targetHours)
    }

    func stopFasting() {
        currentSession?.endTime = .now
        try? context.save()
        cancelNotification()
        fetchData()
    }

    func fetchData() {
        let descriptor = FetchDescriptor<FastingSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        let all = (try? context.fetch(descriptor)) ?? []
        currentSession = all.first { $0.isActive }
        history = all.filter { !$0.isActive }

        if let active = currentSession {
            targetHours = active.targetHours
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func scheduleNotification(targetDate: Date, hours: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Fasting Complete!"
        content.body = "You've completed your \(hours)-hour fast. Great job!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, targetDate.timeIntervalSince(.now)),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "fasting-complete",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["fasting-complete"]
        )
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
