import SwiftUI

struct RecipeRow: View {
    let recipe: Recipe
    var onToggleFavorite: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                HStack(spacing: 8) {
                    if let cal = recipe.caloriesPerServing {
                        Label("\(cal) kcal", systemImage: "flame")
                    }
                    if recipe.totalTimeMinutes > 0 {
                        Label("\(recipe.totalTimeMinutes) min", systemImage: "clock")
                    }
                    Text("\(recipe.ingredients.count) ingredients")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if !recipe.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(recipe.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.fill.tertiary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()

            Button {
                onToggleFavorite()
            } label: {
                Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(recipe.isFavorite ? .red : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
