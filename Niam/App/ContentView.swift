import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedTab: AppTab = .browse
    @State private var showOnboarding = false
    @State private var hasCheckedProfile = false
    @State private var isFirstLaunch = false

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView {
                    showOnboarding = false
                    isFirstLaunch = true
                    selectedTab = .kitchen  // Guide to Kitchen to add first items
                }
            } else {
                mainTabView
            }
        }
        .onAppear {
            guard !hasCheckedProfile else { return }
            hasCheckedProfile = true
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = (try? context.fetch(descriptor)) ?? []
            if profiles.isEmpty {
                showOnboarding = true
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "magnifyingglass")
                }
                .tag(AppTab.browse)

            KitchenView()
                .tabItem {
                    Label("Niam", systemImage: "book")
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
            UserProfile.self,
            WaterIntake.self
        ], inMemory: true)
}
