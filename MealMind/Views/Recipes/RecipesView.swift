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
                        Button {
                            vm.showFavoritesOnly.toggle()
                        } label: {
                            Image(systemName: vm.showFavoritesOnly ? "heart.fill" : "heart")
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
