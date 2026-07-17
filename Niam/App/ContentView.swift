import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .fridge

    var body: some View {
        TabView(selection: $selectedTab) {
            FridgeView()
                .tabItem {
                    Label("Fridge", systemImage: "refrigerator")
                }
                .tag(AppTab.fridge)

            RecipesView()
                .tabItem {
                    Label("Recipes", systemImage: "book")
                }
                .tag(AppTab.recipes)

            TrackerView()
                .tabItem {
                    Label("Tracker", systemImage: "chart.bar")
                }
                .tag(AppTab.tracker)

            FastingView()
                .tabItem {
                    Label("Fasting", systemImage: "timer")
                }
                .tag(AppTab.fasting)

            RecommendView()
                .tabItem {
                    Label("Recommend", systemImage: "sparkles")
                }
                .tag(AppTab.recommend)
        }
    }
}

enum AppTab: Hashable {
    case fridge
    case recipes
    case tracker
    case fasting
    case recommend
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
