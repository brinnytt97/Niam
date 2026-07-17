import Foundation
import SwiftData

struct RecommendationService {

    struct ScoredRecipe {
        let recipe: Recipe
        let matchRatio: Double
        let matchedIngredients: [String]
        let missingIngredients: [String]
        let caloriesFit: Bool
    }

    static func recommend(
        recipes: [Recipe],
        fridgeItems: [FridgeItem],
        remainingCalories: Int?,
        filters: RecommendationFilters = .init()
    ) -> [ScoredRecipe] {
        let fridgeNames = Set(fridgeItems.map { $0.name.lowercased() })

        var scored = recipes.compactMap { recipe -> ScoredRecipe? in
            let recipeIngredientNames = recipe.allIngredients.map { $0.name.lowercased() }

            let matched = recipeIngredientNames.filter { fridgeNames.contains($0) }
            let missing = recipeIngredientNames.filter { !fridgeNames.contains($0) }

            guard !recipeIngredientNames.isEmpty else { return nil }
            let ratio = Double(matched.count) / Double(recipeIngredientNames.count)

            guard ratio >= filters.minimumMatchRatio else { return nil }

            // Apply scene filter
            if let requiredScene = filters.scene {
                guard recipe.hasScene(requiredScene) else { return nil }
            }

            // Apply time filter
            if let maxTime = filters.maxTimeMinutes {
                guard recipe.totalTimeMinutes <= maxTime else { return nil }
            }

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

        scored.sort { a, b in
            if a.caloriesFit != b.caloriesFit { return a.caloriesFit }
            return a.matchRatio > b.matchRatio
        }

        return scored
    }
}

struct RecommendationFilters {
    var minimumMatchRatio: Double = 0.5
    var scene: MealScene? = nil
    var maxTimeMinutes: Int? = nil
}
