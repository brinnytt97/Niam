import Foundation
import SwiftData
import UserNotifications
import Observation

@Observable
final class FridgeViewModel {
    var items: [FridgeItem] = []
    var searchText: String = ""
    var selectedCategory: FoodCategory?

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        fetchItems()
    }

    var filteredItems: [FridgeItem] {
        var result = items
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        return result
    }

    var expiringSoonItems: [FridgeItem] {
        items.filter { $0.isExpiringSoon }
    }

    var expiredItems: [FridgeItem] {
        items.filter { $0.isExpired }
    }

    func fetchItems() {
        let descriptor = FetchDescriptor<FridgeItem>(
            sortBy: [SortDescriptor(\.expirationDate)]
        )
        items = (try? context.fetch(descriptor)) ?? []
    }

    func addItem(_ item: FridgeItem) {
        context.insert(item)
        try? context.save()
        if item.expirationDate != nil {
            requestNotificationPermissionIfNeeded()
            ExpirationNotificationService.schedule(for: item)
        }
        fetchItems()
    }

    private func requestNotificationPermissionIfNeeded() {
        let key = "hasRequestedNotificationPermission_expiration"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func deleteItem(_ item: FridgeItem) {
        ExpirationNotificationService.cancel(for: item)
        context.delete(item)
        try? context.save()
        fetchItems()
    }
}
