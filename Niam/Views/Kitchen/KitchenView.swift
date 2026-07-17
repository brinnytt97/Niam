import SwiftUI
import SwiftData

struct KitchenView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedSegment = 0  // 0=Recipes, 1=Fridge
    @State private var showingAddRecipe = false
    @State private var showingAddFridgeItem = false

    // Recipe state
    @State private var recipesVM: RecipesViewModel?

    // Fridge state
    @State private var fridgeVM: FridgeViewModel?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Header
                VStack(spacing: 16) {
                    HStack {
                        Text("My Kitchen")
                            .font(.system(size: 28, weight: .bold))
                        Spacer()
                    }
                    .padding(.horizontal, 24)

                    // Segmented control
                    Picker("", selection: $selectedSegment) {
                        Text("Recipes").tag(0)
                        Text("Fridge").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                }
                .padding(.top, 8)
                .padding(.bottom, 12)

                Divider()

                // MARK: - Content
                if selectedSegment == 0 {
                    recipeContent
                } else {
                    fridgeContent
                }
            }
            .background(.white)
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .sheet(isPresented: $showingAddRecipe) {
                AddRecipeView { recipe in
                    recipesVM?.addRecipe(recipe)
                }
            }
            .sheet(isPresented: $showingAddFridgeItem) {
                AddFridgeItemView { item in
                    fridgeVM?.addItem(item)
                }
            }
            .onAppear {
                if recipesVM == nil { recipesVM = RecipesViewModel(context: context) }
                if fridgeVM == nil { fridgeVM = FridgeViewModel(context: context) }
            }
        }
    }

    // MARK: - Recipe Content

    private var recipeContent: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Search
                    if let vm = recipesVM {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.gray)
                            TextField("Search recipes...", text: Bindable(vm).searchText)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                        // Scene filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                sceneChip("All", scene: nil, vm: vm)
                                ForEach(MealScene.allCases, id: \.self) { scene in
                                    sceneChip(scene.rawValue, scene: scene, vm: vm)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.bottom, 12)

                        // Recipe list
                        if vm.filteredRecipes.isEmpty {
                            ContentUnavailableView(
                                "No Recipes",
                                systemImage: "book",
                                description: Text("Tap + to add your first recipe")
                            )
                            .padding(.top, 60)
                        } else {
                            ForEach(vm.filteredRecipes) { recipe in
                                NavigationLink(value: recipe) {
                                    KitchenRecipeRow(recipe: recipe) {
                                        vm.toggleFavorite(recipe)
                                    }
                                }
                                .buttonStyle(.plain)
                                Divider().padding(.leading, 88).padding(.horizontal, 24)
                            }
                        }
                    }
                }
            }

            // FAB
            fabButton { showingAddRecipe = true }
        }
    }

    // MARK: - Fridge Content

    private var fridgeContent: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if let vm = fridgeVM {
                        // Search
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.gray)
                            TextField("Search ingredients...", text: Bindable(vm).searchText)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                        if vm.filteredItems.isEmpty {
                            ContentUnavailableView(
                                "Fridge is empty",
                                systemImage: "refrigerator",
                                description: Text("Tap + to add ingredients")
                            )
                            .padding(.top, 60)
                        } else {
                            // Expiring section
                            if !vm.expiringSoonItems.isEmpty {
                                sectionLabel("⚠️ Expiring Soon")
                                ForEach(vm.expiringSoonItems) { item in
                                    KitchenFridgeRow(item: item)
                                    Divider().padding(.leading, 52).padding(.horizontal, 24)
                                }
                            }

                            // All items
                            sectionLabel("All Items (\(vm.filteredItems.count))")
                            ForEach(vm.filteredItems) { item in
                                KitchenFridgeRow(item: item)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            vm.deleteItem(item)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                Divider().padding(.leading, 52).padding(.horizontal, 24)
                            }
                        }
                    }
                }
            }

            // FAB
            fabButton { showingAddFridgeItem = true }
        }
    }

    // MARK: - Components

    private func sceneChip(_ label: String, scene: MealScene?, vm: RecipesViewModel) -> some View {
        let isSelected = vm.filterScene == scene
        return Button {
            vm.filterScene = scene
        } label: {
            Text(label)
                .font(.caption.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? .black : .white)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color(.systemGray4), lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fabButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color(red: 0.95, green: 0.22, blue: 0.24))
                .clipShape(Circle())
                .shadow(color: Color(red: 0.95, green: 0.22, blue: 0.24).opacity(0.3), radius: 8, y: 4)
        }
        .padding(.trailing, 24)
        .padding(.bottom, 24)
    }
}

// MARK: - Kitchen Recipe Row

private struct KitchenRecipeRow: View {
    let recipe: Recipe
    var onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Color block thumbnail with emoji
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(thumbnailColor)
                    .frame(width: 64, height: 64)
                Text(thumbnailEmoji)
                    .font(.title)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    ForEach(recipe.scenes.prefix(2), id: \.self) { scene in
                        Text(scene.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(recipe.cuisine.rawValue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    if let cal = recipe.caloriesPerServing {
                        Text("\(cal) kcal")
                    }
                    if recipe.totalTimeMinutes > 0 {
                        Text("\(recipe.totalTimeMinutes) min")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button { onToggleFavorite() } label: {
                Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(recipe.isFavorite ? .red : .gray.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    private var thumbnailColor: Color {
        if recipe.scenes.contains(.breakfast) { return Color(red: 1, green: 0.95, blue: 0.90) }
        if recipe.scenes.contains(.dessert) { return Color(red: 0.97, green: 0.92, blue: 0.97) }
        if recipe.scenes.contains(.drink) { return Color(red: 0.90, green: 0.95, blue: 1) }
        return Color(red: 0.92, green: 0.97, blue: 0.93)
    }

    private var thumbnailEmoji: String {
        if recipe.scenes.contains(.breakfast) { return "🍳" }
        if recipe.scenes.contains(.dessert) { return "🍰" }
        if recipe.scenes.contains(.drink) { return "🥤" }
        if recipe.scenes.contains(.mainMeal) { return "🥘" }
        return "🍽️"
    }
}

// MARK: - Kitchen Fridge Row

private struct KitchenFridgeRow: View {
    let item: FridgeItem

    var body: some View {
        HStack(spacing: 14) {
            Text(emojiForCategory(item.category))
                .font(.title2)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                Text("\(item.quantity, specifier: "%.1f") \(item.unit.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if item.isExpired {
                Text("Expired")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.red)
            } else if item.isExpiringSoon {
                Text("Expiring")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
            } else if let date = item.expirationDate {
                Text(date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    private func emojiForCategory(_ cat: FoodCategory) -> String {
        switch cat {
        case .vegetable: "🥬"
        case .fruit: "🍎"
        case .meat: "🍗"
        case .seafood: "🐟"
        case .dairy: "🥛"
        case .grain: "🍞"
        case .condiment: "🧂"
        case .beverage: "🥤"
        case .frozen: "🧊"
        case .snack: "🍪"
        case .other: "📦"
        }
    }
}
