import SwiftUI
import SwiftData

@main
struct NiamApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            FridgeItem.self,
            Recipe.self,
            MealRecord.self,
            FastingSession.self,
            UserProfile.self,
            WaterIntake.self,
            DrinkEntry.self
        ])
    }
}
