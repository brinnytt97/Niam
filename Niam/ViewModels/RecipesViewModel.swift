import Foundation
import SwiftData
import Observation

@Observable
final class RecipesViewModel {
    var recipes: [Recipe] = []
    var searchText: String = ""
    var showFavoritesOnly: Bool = false

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        fetchRecipes()
    }

    var filteredRecipes: [Recipe] {
        var result = recipes
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        if showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }
        return result
    }

    func fetchRecipes() {
        let descriptor = FetchDescriptor<Recipe>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        recipes = (try? context.fetch(descriptor)) ?? []
    }

    func addRecipe(_ recipe: Recipe) {
        context.insert(recipe)
        try? context.save()
        fetchRecipes()
    }

    func deleteRecipe(_ recipe: Recipe) {
        context.delete(recipe)
        try? context.save()
        fetchRecipes()
    }

    func toggleFavorite(_ recipe: Recipe) {
        recipe.isFavorite.toggle()
        try? context.save()
    }
}
