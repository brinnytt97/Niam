import SwiftUI
import SwiftData

struct RecipesView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel: RecipesViewModel?
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    RecipeListContent(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Recipes")
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if let vm = viewModel {
                        Menu {
                            Button {
                                vm.showFavoritesOnly.toggle()
                            } label: {
                                Label(
                                    vm.showFavoritesOnly ? "Show All" : "Favorites Only",
                                    systemImage: vm.showFavoritesOnly ? "heart.slash" : "heart.fill"
                                )
                            }

                            Menu("Filter by Scene") {
                                Button("All") { vm.filterScene = nil }
                                ForEach(MealScene.allCases, id: \.self) { scene in
                                    Button(scene.rawValue) { vm.filterScene = scene }
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddRecipeView { recipe in
                    viewModel?.addRecipe(recipe)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = RecipesViewModel(context: context)
                }
            }
        }
    }
}

private struct RecipeListContent: View {
    @Bindable var viewModel: RecipesViewModel

    var body: some View {
        List {
            ForEach(viewModel.filteredRecipes) { recipe in
                NavigationLink(value: recipe) {
                    RecipeRow(recipe: recipe, onToggleFavorite: {
                        viewModel.toggleFavorite(recipe)
                    })
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    viewModel.deleteRecipe(viewModel.filteredRecipes[index])
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search recipes...")
        .overlay {
            if viewModel.recipes.isEmpty {
                ContentUnavailableView(
                    "No Recipes",
                    systemImage: "book",
                    description: Text("Tap + to add your first recipe")
                )
            }
        }
    }
}
