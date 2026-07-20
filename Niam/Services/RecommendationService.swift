import Foundation
import SwiftData

struct RecommendationService {

    struct ScoredRecipe {
        let recipe: Recipe
        let score: Double
        let matchRatio: Double
        let matchedIngredients: [String]
        let missingIngredients: [String]
        let caloriesFit: Bool
    }

    /// Smart recommendation with weighted scoring:
    /// - Ingredient match: 40%
    /// - Cuisine preference: 25%
    /// - Scene match (time-based): 20%
    /// - Calorie fit: 15%
    static func recommend(
        recipes: [Recipe],
        fridgeItems: [FridgeItem],
        remainingCalories: Int?,
        filters: RecommendationFilters = .init(),
        preferences: UserPreferences = .init()
    ) -> [ScoredRecipe] {
        let fridgeNames = Set(fridgeItems.map { $0.name.lowercased() })

        var scored = recipes.compactMap { recipe -> ScoredRecipe? in
            let recipeIngredientNames = recipe.allIngredients.map { $0.name.lowercased() }

            let matched = recipeIngredientNames.filter { fridgeNames.contains($0) }
            let missing = recipeIngredientNames.filter { !fridgeNames.contains($0) }

            let ingredientRatio: Double
            if recipeIngredientNames.isEmpty {
                ingredientRatio = 0
            } else {
                ingredientRatio = Double(matched.count) / Double(recipeIngredientNames.count)
            }

            // Apply hard filters
            if let requiredScene = filters.scene {
                guard recipe.hasScene(requiredScene) else { return nil }
            }

            if let maxTime = filters.maxTimeMinutes {
                guard recipe.totalTimeMinutes <= maxTime else { return nil }
            }

            // Calorie fit
            var caloriesFit = true
            if let remaining = remainingCalories, let cal = recipe.caloriesPerServing {
                caloriesFit = cal <= remaining
            }

            // Weighted scoring
            let ingredientScore = ingredientRatio * 0.40

            let cuisineScore: Double = preferences.favoriteCuisines.contains(recipe.cuisine) ? 0.25 : 0.0

            let sceneScore: Double
            if let currentScene = filters.scene {
                sceneScore = recipe.hasScene(currentScene) ? 0.20 : 0.0
            } else {
                // Auto-detect by time
                let autoScene = currentMealScene()
                sceneScore = recipe.hasScene(autoScene) ? 0.20 : 0.05
            }

            let calorieScore: Double = caloriesFit ? 0.15 : 0.0

            let totalScore = ingredientScore + cuisineScore + sceneScore + calorieScore

            // Apply minimum threshold
            guard totalScore >= filters.minimumScore else { return nil }

            return ScoredRecipe(
                recipe: recipe,
                score: totalScore,
                matchRatio: ingredientRatio,
                matchedIngredients: matched,
                missingIngredients: missing,
                caloriesFit: caloriesFit
            )
        }

        scored.sort { $0.score > $1.score }

        return scored
    }

    /// Analyze user's saved recipes to determine cuisine preferences
    static func analyzePreferences(recipes: [Recipe]) -> UserPreferences {
        var cuisineCounts: [Cuisine: Int] = [:]
        var sceneCounts: [MealScene: Int] = [:]

        for recipe in recipes where recipe.isFavorite {
            cuisineCounts[recipe.cuisine, default: 0] += 1
            for scene in recipe.scenes {
                sceneCounts[scene, default: 0] += 1
            }
        }

        // Top 3 cuisines
        let topCuisines = cuisineCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
        let topScenes = sceneCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }

        return UserPreferences(
            favoriteCuisines: Set(topCuisines),
            favoriteScenes: Set(topScenes)
        )
    }

    private static func currentMealScene() -> MealScene {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 10 { return .breakfast }
        if hour < 14 { return .mainMeal }
        if hour < 17 { return .snack }
        return .mainMeal
    }
}

struct RecommendationFilters {
    var minimumScore: Double = 0.1
    var minimumMatchRatio: Double = 0.0
    var scene: MealScene? = nil
    var maxTimeMinutes: Int? = nil
}

struct UserPreferences {
    var favoriteCuisines: Set<Cuisine> = []
    var favoriteScenes: Set<MealScene> = []
}
