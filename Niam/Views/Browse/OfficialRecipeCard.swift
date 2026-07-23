import SwiftUI

struct OfficialRecipeCard: View {
    let recipe: OfficialRecipe

    private var cardColor: Color {
        if recipe.scenes.contains("Breakfast") { return Color(red: 1, green: 0.95, blue: 0.90) }
        if recipe.scenes.contains("Dessert") { return Color(red: 0.97, green: 0.92, blue: 0.97) }
        if recipe.scenes.contains("Drink") { return Color(red: 0.90, green: 0.95, blue: 1) }
        return Color(red: 0.92, green: 0.97, blue: 0.93)
    }

    private var emoji: String {
        if recipe.scenes.contains("Breakfast") { return "🍳" }
        if recipe.scenes.contains("Dessert") { return "🍰" }
        if recipe.scenes.contains("Drink") { return "🥤" }
        if recipe.scenes.contains("Snack") { return "🥜" }
        return "🥘"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(emoji)
                    .font(.system(size: 36))
                Spacer()
                Text(recipe.cuisine)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.8))
                    .clipShape(Capsule())
            }
            .padding(.bottom, 40)

            Text(recipe.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .padding(.bottom, 4)

            HStack(spacing: 4) {
                if let cal = recipe.caloriesPerServing {
                    Text("\(cal) kcal")
                }
                if recipe.totalTimeMinutes > 0 {
                    Text("· \(recipe.totalTimeMinutes) min")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 168, height: 180)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
