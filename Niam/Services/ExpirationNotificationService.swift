import Foundation
import UserNotifications
import SwiftData

/// Schedules local notifications for fridge items expiring soon.
enum ExpirationNotificationService {

    private static let notificationPrefix = "expiration-"

    /// Schedule a notification for 1 day before expiration.
    static func schedule(for item: FridgeItem) {
        guard let expirationDate = item.expirationDate else { return }

        // Notify 1 day before expiration, at 9:00 AM
        guard let notifyDate = Calendar.current.date(byAdding: .day, value: -1, to: expirationDate) else { return }

        // Don't schedule if already past
        guard notifyDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Food Expiring Tomorrow"
        content.body = "\(item.name) expires tomorrow. Use it or lose it!"
        content.sound = .default

        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: notifyDate)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "\(notificationPrefix)\(item.name)-\(item.addedDate.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Cancel notification for a specific item.
    static func cancel(for item: FridgeItem) {
        let id = "\(notificationPrefix)\(item.name)-\(item.addedDate.timeIntervalSince1970)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Reschedule all notifications for current fridge items.
    static func rescheduleAll(context: ModelContext) {
        // Clear all expiration notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let expirationIds = requests
                .filter { $0.identifier.hasPrefix(notificationPrefix) }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: expirationIds)
        }

        // Reschedule for all items with expiration dates
        let descriptor = FetchDescriptor<FridgeItem>()
        guard let items = try? context.fetch(descriptor) else { return }

        for item in items where item.expirationDate != nil {
            schedule(for: item)
        }
    }
}
