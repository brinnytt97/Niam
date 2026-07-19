import SwiftUI
import SwiftData

struct BrowseSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var query = ""
    @State private var recipeResults: [Recipe] = []
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray)
                    TextField("Search recipes, ingredients...", text: $query)
                        .font(.subheadline)
                        .focused($isSearchFocused)
                        .onChange(of: query) { _, _ in search() }
                    if !query.isEmpty {
                        Button {
                            query = ""
                            recipeResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Divider().padding(.top, 12)

                // Results
                if query.isEmpty {
                    emptySearchState
                } else if recipeResults.isEmpty {
                    noResultsState
                } else {
                    resultsList
                }

                Spacer()
            }
            .background(.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .onAppear { isSearchFocused = true }
        }
    }

    // MARK: - Empty state (before typing)

    private var emptySearchState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.gray.opacity(0.3))
            Text("Search your recipes")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("By name, ingredient, cuisine, or meal scene")
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }

    // MARK: - No results

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 60)
            Text("No results for \"\(query)\"")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Results list

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if !recipeResults.isEmpty {
                    Text("Recipes (\(recipeResults.count))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    ForEach(recipeResults) { recipe in
                        NavigationLink(value: recipe) {
                            SearchResultRow(recipe: recipe, query: query)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.leading, 68).padding(.horizontal, 24)
                    }
                }
            }
        }
    }

    // MARK: - Search logic

    private func search() {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else {
            recipeResults = []
            return
        }

        let descriptor = FetchDescriptor<Recipe>()
        guard let allRecipes = try? context.fetch(descriptor) else { return }

        recipeResults = allRecipes.filter { recipe in
            // Match recipe title
            if recipe.title.localizedCaseInsensitiveContains(q) { return true }
            // Match cuisine
            if recipe.cuisine.rawValue.localizedCaseInsensitiveContains(q) { return true }
            // Match scenes
            if recipe.scenes.contains(where: { $0.rawValue.localizedCaseInsensitiveContains(q) }) { return true }
            // Match ingredients
            if recipe.allIngredients.contains(where: { $0.name.localizedCaseInsensitiveContains(q) }) { return true }
            return false
        }
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    let recipe: Recipe
    let query: String

    private var matchInfo: String {
        let q = query.lowercased()
        if recipe.cuisine.rawValue.localizedCaseInsensitiveContains(q) {
            return "Cuisine: \(recipe.cuisine.rawValue)"
        }
        if let scene = recipe.scenes.first(where: { $0.rawValue.localizedCaseInsensitiveContains(q) }) {
            return "Scene: \(scene.rawValue)"
        }
        if let ing = recipe.allIngredients.first(where: { $0.name.localizedCaseInsensitiveContains(q) }) {
            return "Ingredient: \(ing.name)"
        }
        return recipe.scenes.first?.rawValue ?? ""
    }

    var body: some View {
        HStack(spacing: 14) {
            // Emoji thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
                    .frame(width: 44, height: 44)
                Text(sceneEmoji)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(matchInfo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if let cal = recipe.caloriesPerServing {
                Text("\(cal) kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.gray.opacity(0.4))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    private var sceneEmoji: String {
        if recipe.scenes.contains(.breakfast) { return "🍳" }
        if recipe.scenes.contains(.dessert) { return "🍰" }
        if recipe.scenes.contains(.drink) { return "🥤" }
        if recipe.scenes.contains(.mainMeal) { return "🥘" }
        return "🍽️"
    }
}
