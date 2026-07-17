import SwiftUI
import SwiftData

struct AddMealRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var mealType: MealType = .lunch
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var notes = ""

    // Recipe picker
    @State private var showingRecipePicker = false
    @State private var recipes: [Recipe] = []

    // Nutrition search
    @State private var searchResults: [NutritionService.FoodItem] = []
    @State private var isSearching = false

    var onSave: (MealRecord) -> Void

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Pick from Recipe
                Section {
                    Button {
                        loadRecipes()
                        showingRecipePicker = true
                    } label: {
                        Label("Pick from My Recipes", systemImage: "book.fill")
                    }
                }

                // MARK: - Food Name + USDA Search
                Section("Food") {
                    TextField("Food name", text: $name)
                        .onSubmit { searchNutrition() }

                    if isSearching {
                        ProgressView("Searching USDA database...")
                    }

                    if !searchResults.isEmpty {
                        ForEach(searchResults) { food in
                            Button {
                                applyNutrition(food)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(food.description)
                                        .font(.subheadline)
                                    if let cal = food.calories {
                                        Text("\(cal) kcal")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }

                // MARK: - Meal Type
                Section("Meal Type") {
                    Picker("Type", selection: $mealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: - Nutrition
                Section("Nutrition (per serving)") {
                    NutritionRow(label: "Calories", value: $calories, unit: "kcal", isInteger: true)
                    NutritionRow(label: "Protein", value: $protein, unit: "g", isInteger: false)
                    NutritionRow(label: "Carbs", value: $carbs, unit: "g", isInteger: false)
                    NutritionRow(label: "Fat", value: $fat, unit: "g", isInteger: false)
                }

                // MARK: - Notes
                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2)
                }
            }
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let record = MealRecord(
                            name: name,
                            mealType: mealType,
                            calories: Int(calories) ?? 0,
                            protein: Double(protein) ?? 0,
                            carbs: Double(carbs) ?? 0,
                            fat: Double(fat) ?? 0,
                            notes: notes
                        )
                        onSave(record)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingRecipePicker) {
                RecipePickerSheet(recipes: recipes) { recipe in
                    applyRecipe(recipe)
                }
            }
        }
    }

    private func loadRecipes() {
        let descriptor = FetchDescriptor<Recipe>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        recipes = (try? context.fetch(descriptor)) ?? []
    }

    private func applyRecipe(_ recipe: Recipe) {
        name = recipe.title
        if let cal = recipe.caloriesPerServing {
            calories = String(cal)
        }
        // Map first recipe scene to meal type
        if let firstScene = recipe.scenes.first {
            switch firstScene {
            case .breakfast: mealType = .breakfast
            case .mainMeal, .lateNight: mealType = .dinner
            case .afternoonTea, .snack: mealType = .snack
            case .drink, .dessert: mealType = .snack
            }
        }
    }

    private func searchNutrition() {
        guard !name.isEmpty else { return }
        isSearching = true
        Task {
            do {
                searchResults = try await NutritionService.search(query: name)
            } catch {
                searchResults = []
            }
            isSearching = false
        }
    }

    private func applyNutrition(_ food: NutritionService.FoodItem) {
        if let cal = food.calories { calories = String(cal) }
        if let p = food.protein { protein = String(format: "%.1f", p) }
        if let c = food.carbs { carbs = String(format: "%.1f", c) }
        if let f = food.fat { fat = String(format: "%.1f", f) }
        searchResults = []
    }
}

// MARK: - Recipe Picker Sheet

private struct RecipePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let recipes: [Recipe]
    let onPick: (Recipe) -> Void

    @State private var searchText = ""

    var filtered: [Recipe] {
        if searchText.isEmpty { return recipes }
        return recipes.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { recipe in
                Button {
                    onPick(recipe)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.title)
                                .font(.headline)
                            HStack(spacing: 6) {
                                ForEach(recipe.scenes.prefix(2), id: \.self) { scene in
                                    Text(scene.rawValue)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.orange.opacity(0.15))
                                        .foregroundStyle(.orange)
                                        .clipShape(Capsule())
                                }
                                if let cal = recipe.caloriesPerServing {
                                    Text("\(cal) kcal")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
            }
            .searchable(text: $searchText, prompt: "Search recipes...")
            .navigationTitle("Pick Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if recipes.isEmpty {
                    ContentUnavailableView(
                        "No Recipes",
                        systemImage: "book",
                        description: Text("Add recipes first")
                    )
                }
            }
        }
    }
}

// MARK: - Nutrition Row

private struct NutritionRow: View {
    let label: String
    @Binding var value: String
    let unit: String
    let isInteger: Bool

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField(unit, text: $value)
                .keyboardType(isInteger ? .numberPad : .decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
        }
    }
}
