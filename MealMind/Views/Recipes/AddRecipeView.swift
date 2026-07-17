import SwiftUI

struct AddRecipeView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var summary = ""
    @State private var servings = 2
    @State private var prepTime = 10
    @State private var cookTime = 20
    @State private var caloriesText = ""
    @State private var tagsText = ""
    @State private var ingredients: [Ingredient] = []
    @State private var steps: [String] = []
    @State private var showingAddIngredient = false

    // New ingredient fields
    @State private var newIngredientName = ""
    @State private var newIngredientQty: Double = 1
    @State private var newIngredientUnit: FoodUnit = .gram

    // New step
    @State private var newStep = ""

    var onSave: (Recipe) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Recipe Title", text: $title)
                    TextField("Summary", text: $summary, axis: .vertical)
                        .lineLimit(3)
                    Stepper("Servings: \(servings)", value: $servings, in: 1...20)
                    Stepper("Prep: \(prepTime) min", value: $prepTime, in: 0...300, step: 5)
                    Stepper("Cook: \(cookTime) min", value: $cookTime, in: 0...300, step: 5)
                    TextField("Calories per serving", text: $caloriesText)
                        .keyboardType(.numberPad)
                    TextField("Tags (comma separated)", text: $tagsText)
                }

                Section("Ingredients (\(ingredients.count))") {
                    ForEach(ingredients, id: \.self) { ing in
                        Text("\(ing.quantity, specifier: "%.1f") \(ing.unit.rawValue) \(ing.name)")
                    }
                    .onDelete { ingredients.remove(atOffsets: $0) }

                    HStack {
                        TextField("Name", text: $newIngredientName)
                        TextField("Qty", value: $newIngredientQty, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 50)
                        Picker("", selection: $newIngredientUnit) {
                            ForEach(FoodUnit.allCases, id: \.self) { u in
                                Text(u.rawValue).tag(u)
                            }
                        }
                        .frame(width: 70)
                        Button {
                            guard !newIngredientName.isEmpty else { return }
                            ingredients.append(Ingredient(
                                name: newIngredientName,
                                quantity: newIngredientQty,
                                unit: newIngredientUnit
                            ))
                            newIngredientName = ""
                            newIngredientQty = 1
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }

                Section("Steps (\(steps.count))") {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        Text("\(index + 1). \(step)")
                    }
                    .onDelete { steps.remove(atOffsets: $0) }

                    HStack {
                        TextField("Add a step...", text: $newStep)
                        Button {
                            guard !newStep.isEmpty else { return }
                            steps.append(newStep)
                            newStep = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .navigationTitle("New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let tags = tagsText.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                        let recipe = Recipe(
                            title: title,
                            summary: summary,
                            ingredients: ingredients,
                            steps: steps,
                            servings: servings,
                            prepTimeMinutes: prepTime,
                            cookTimeMinutes: cookTime,
                            caloriesPerServing: Int(caloriesText),
                            tags: tags
                        )
                        onSave(recipe)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
