import SwiftUI
import SwiftData

struct OfficialRecipeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let recipe: OfficialRecipe
    var onSave: (Recipe) -> Void

    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Meta
                HStack(spacing: 12) {
                    if let cal = recipe.caloriesPerServing {
                        metaBadge(label: "\(cal) kcal", icon: "flame")
                    }
                    if recipe.totalTimeMinutes > 0 {
                        metaBadge(label: "\(recipe.totalTimeMinutes) min", icon: "clock")
                    }
                    if let serv = recipe.servings {
                        metaBadge(label: "\(serv) servings", icon: "person.2")
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)

                    // MARK: - Ingredients
                    if !recipe.mainIngredients.isEmpty {
                        ingredientSection("Main Ingredients", items: recipe.mainIngredients)
                    }
                    if !recipe.sideIngredients.isEmpty {
                        ingredientSection("Side Ingredients", items: recipe.sideIngredients)
                    }
                    if !recipe.seasonings.isEmpty {
                        ingredientSection("Seasonings", items: recipe.seasonings)
                    }

                    // MARK: - Steps
                    if !recipe.steps.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Steps")
                                .font(.headline)
                                .padding(.horizontal, 20)
                            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 22, height: 22)
                                        .background(Color.accentColor)
                                        .clipShape(Circle())
                                    Text(step)
                                        .font(.subheadline)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    // MARK: - Notes
                    if !recipe.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes")
                                .font(.headline)
                            Text(recipe.notes)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                    }

                    // MARK: - Save button
                    Button {
                        saveToMyRecipes()
                    } label: {
                        Label(saved ? "Saved to My Recipes" : "Save to My Recipes",
                              systemImage: saved ? "checkmark.circle.fill" : "plus.circle")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(saved ? Color(.systemGray5) : Color.accentColor)
                            .foregroundStyle(saved ? Color.secondary : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(saved)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .padding(.top, 16)
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
    }

    private func metaBadge(label: String, icon: String) -> some View {
        Label(label, systemImage: icon)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
    }

    private func ingredientSection(_ title: String, items: [RemoteIngredient]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 20)
            ForEach(items, id: \.name) { ing in
                HStack {
                    Text(ing.name)
                        .font(.subheadline)
                    Spacer()
                    Text("\(ing.quantity.formatted()) \(ing.unit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }

    private func saveToMyRecipes() {
        let cuisine = Cuisine(rawValue: recipe.cuisine) ?? .other
        let scenes = recipe.scenes.compactMap { MealScene(rawValue: $0) }
        let main = recipe.mainIngredients.map { Ingredient(name: $0.name, quantity: $0.quantity, unit: FoodUnit(rawValue: $0.unit) ?? .gram) }
        let side = recipe.sideIngredients.map { Ingredient(name: $0.name, quantity: $0.quantity, unit: FoodUnit(rawValue: $0.unit) ?? .gram) }
        let season = recipe.seasonings.map { Ingredient(name: $0.name, quantity: $0.quantity, unit: FoodUnit(rawValue: $0.unit) ?? .gram) }

        let local = Recipe(
            title: recipe.title,
            cuisine: cuisine,
            scenes: scenes.isEmpty ? [.mainMeal] : scenes,
            mainIngredients: main,
            sideIngredients: side,
            seasonings: season,
            steps: recipe.steps,
            notes: recipe.notes,
            servings: recipe.servings,
            prepTimeMinutes: recipe.prepTimeMinutes,
            cookTimeMinutes: recipe.cookTimeMinutes,
            caloriesPerServing: recipe.caloriesPerServing
        )
        onSave(local)
        saved = true
    }
}
