import SwiftUI

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var context
    let recipe: Recipe
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Hero Image
                if let data = recipe.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipped()
                }

                VStack(alignment: .leading, spacing: 16) {
                    // MARK: - Title & Tags
                    Text(recipe.title)
                        .font(.largeTitle.bold())

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(recipe.scenes, id: \.self) { scene in
                                TagBadge(text: scene.rawValue, color: .orange)
                            }
                            TagBadge(text: recipe.cuisine.rawValue, color: .blue)
                        }
                    }

                    // MARK: - Quick Info
                    HStack(spacing: 20) {
                        if let servings = recipe.servings {
                            InfoItem(icon: "person.2", label: "Servings", value: "\(servings)")
                        }
                        if recipe.prepTimeMinutes > 0 {
                            InfoItem(icon: "hands.sparkles", label: "Prep", value: "\(recipe.prepTimeMinutes) min")
                        }
                        if recipe.cookTimeMinutes > 0 {
                            InfoItem(icon: "frying.pan", label: "Cook", value: "\(recipe.cookTimeMinutes) min")
                        }
                        if let cal = recipe.caloriesPerServing {
                            InfoItem(icon: "flame", label: "Calories", value: "\(cal) kcal")
                        }
                    }
                    .padding()
                    .background(.fill.tertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // MARK: - Main Ingredients
                    if !recipe.mainIngredients.isEmpty {
                        IngredientSectionView(
                            title: "Main Ingredients",
                            icon: "star.fill",
                            ingredients: recipe.mainIngredients
                        )
                    }

                    // MARK: - Side Ingredients
                    if !recipe.sideIngredients.isEmpty {
                        IngredientSectionView(
                            title: "Side Ingredients",
                            icon: "leaf",
                            ingredients: recipe.sideIngredients
                        )
                    }

                    // MARK: - Seasonings
                    if !recipe.seasonings.isEmpty {
                        IngredientSectionView(
                            title: "Seasonings",
                            icon: "drop.fill",
                            ingredients: recipe.seasonings
                        )
                    }

                    // MARK: - Steps
                    if !recipe.steps.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Steps", systemImage: "list.number")
                                .font(.title3.bold())

                            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .frame(width: 28, height: 28)
                                        .background(Color.accentColor)
                                        .clipShape(Circle())

                                    Text(step)
                                        .font(.body)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    // MARK: - Notes
                    if !recipe.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Notes", systemImage: "note.text")
                                .font(.title3.bold())
                            Text(recipe.notes)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(recipe.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEdit = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddRecipeView(editingRecipe: recipe) { _ in
                try? context.save()
            }
        }
    }
}

private struct TagBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

private struct InfoItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct IngredientSectionView: View {
    let title: String
    let icon: String
    let ingredients: [Ingredient]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.title3.bold())

            ForEach(ingredients, id: \.self) { ing in
                HStack {
                    Text(ing.name)
                    Spacer()
                    Text("\(ing.quantity, specifier: "%.1f") \(ing.unit.rawValue)")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
                Divider()
            }
        }
    }
}
