import Foundation
import SwiftData
import Observation

@Observable
final class RecommendViewModel {
    var recommendations: [RecommendationService.ScoredRecipe] = []
    var filters = RecommendationFilters()
    var selectedMeal: MealScene? = nil
    var isLoading = false

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func generateRecommendations() {
        isLoading = true
        defer { isLoading = false }

        let fridgeDescriptor = FetchDescriptor<FridgeItem>()
        let recipeDescriptor = FetchDescriptor<Recipe>()
        let recordDescriptor = FetchDescriptor<MealRecord>()
        let profileDescriptor = FetchDescriptor<UserProfile>()

        guard
            let fridgeItems = try? context.fetch(fridgeDescriptor),
            let recipes = try? context.fetch(recipeDescriptor)
        else { return }

        let records = (try? context.fetch(recordDescriptor)) ?? []
        let profile = (try? context.fetch(profileDescriptor))?.first

        // For breakfast, don't filter by calories
        let remaining: Int?
        if selectedMeal == .breakfast {
            remaining = nil
        } else {
            remaining = profile.map {
                CalorieCalculator.remainingCalories(
                    target: $0.dailyCalorieTarget,
                    consumed: records
                )
            }
        }

        var activeFilters = filters
        activeFilters.scene = selectedMeal

        recommendations = RecommendationService.recommend(
            recipes: recipes,
            fridgeItems: fridgeItems,
            remainingCalories: remaining,
            filters: activeFilters
        )
    }
}
