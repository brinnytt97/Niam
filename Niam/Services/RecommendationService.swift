import Foundation
import SwiftData

/// Rule-based recommendation engine.
/// Matches fridge ingredients against recipes and ranks by:
/// 1. Ingredient match ratio (how many recipe ingredients are in the fridge)
/// 2. Calorie fit (how well it fits remaining daily budget)
struct RecommendationService {

    struct ScoredRecipe {
        let recipe: Recipe
        let matchRatio: Double      // 0.0 to 1.0
        let matchedIngredients: [String]
        let missingIngredients: [String]
        let caloriesFit: Bool
    }

    /// Recommend recipes based on available ingredients and calorie budget.
    static func recommend(
        recipes: [Recipe],
        fridgeItems: [FridgeItem],
        remainingCalories: Int?,
        filters: RecommendationFilters = .init()
    ) -> [ScoredRecipe] {
        let fridgeNames = Set(fridgeItems.map { $0.name.lowercased() })

        var scored = recipes.compactMap { recipe -> ScoredRecipe? in
            let recipeIngredientNames = recipe.ingredients.map { $0.name.lowercased() }

            let matched = recipeIngredientNames.filter { fridgeNames.contains($0) }
            let missing = recipeIngredientNames.filter { !fridgeNames.contains($0) }

            guard !recipeIngredientNames.isEmpty else { return nil }
            let ratio = Double(matched.count) / Double(recipeIngredientNames.count)

            // Apply minimum match filter
            guard ratio >= filters.minimumMatchRatio else { return nil }

            // Apply tag filter
            if let requiredTag = filters.requiredTag {
                guard recipe.tags.contains(requiredTag) else { return nil }
            }

            // Apply time filter
            if let maxTime = filters.maxTimeMinutes {
                guard recipe.totalTimeMinutes <= maxTime else { return nil }
            }

            // Check calorie fit
            var caloriesFit = true
            if let remaining = remainingCalories, let cal = recipe.caloriesPerServing {
                caloriesFit = cal <= remaining
            }

            return ScoredRecipe(
                recipe: recipe,
                matchRatio: ratio,
                matchedIngredients: matched,
                missingIngredients: missing,
                caloriesFit: caloriesFit
            )
        }

        // Sort: calorie-fit first, then by match ratio descending
        scored.sort { a, b in
            if a.caloriesFit != b.caloriesFit { return a.caloriesFit }
            return a.matchRatio > b.matchRatio
        }

        return scored
    }
}

struct RecommendationFilters {
    var minimumMatchRatio: Double = 0.5
    var requiredTag: String? = nil
    var maxTimeMinutes: Int? = nil
}
