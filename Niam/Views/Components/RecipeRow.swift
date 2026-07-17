import SwiftUI

struct RecipeRow: View {
    let recipe: Recipe
    var onToggleFavorite: () -> Void

    var body: some View {
        HStack {
            if let data = recipe.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                HStack(spacing: 4) {
                    ForEach(recipe.scenes.prefix(2), id: \.self) { scene in
                        Text(scene.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.fill.tertiary)
                            .clipShape(Capsule())
                    }
                    Text(recipe.cuisine.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.fill.tertiary)
                        .clipShape(Capsule())
                }
                HStack(spacing: 8) {
                    if let cal = recipe.caloriesPerServing {
                        Label("\(cal) kcal", systemImage: "flame")
                    }
                    if recipe.totalTimeMinutes > 0 {
                        Label("\(recipe.totalTimeMinutes) min", systemImage: "clock")
                    }
                    let count = recipe.mainIngredients.count + recipe.sideIngredients.count
                    if count > 0 {
                        Text("\(count) ingredients")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
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
