import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .browse

    var body: some View {
        TabView(selection: $selectedTab) {
            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "magnifyingglass")
                }
                .tag(AppTab.browse)

            KitchenView()
                .tabItem {
                    Label("Kitchen", systemImage: "refrigerator")
                }
                .tag(AppTab.kitchen)

            TrackerTabView()
                .tabItem {
                    Label("Tracker", systemImage: "chart.bar")
                }
                .tag(AppTab.tracker)

            MeView()
                .tabItem {
                    Label("Me", systemImage: "person")
                }
                .tag(AppTab.me)
        }
        .tint(Color(red: 0.95, green: 0.22, blue: 0.24))
    }
}

enum AppTab: Hashable {
    case browse
    case kitchen
    case tracker
    case me
}

#Preview {
    ContentView()
        .modelContainer(for: [
            FridgeItem.self,
            Recipe.self,
            MealRecord.self,
            FastingSession.self,
            UserProfile.self
        ], inMemory: true)
}
