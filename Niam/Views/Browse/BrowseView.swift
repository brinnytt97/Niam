import SwiftUI
import SwiftData

struct BrowseView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedMeal: MealScene? = nil
    @State private var searchText = ""
    @State private var recommendations: [RecommendationService.ScoredRecipe] = []
    @State private var expiringItems: [FridgeItem] = []
    @State private var userName = "there"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - Hero
                    heroSection

                    // MARK: - Meal Chips
                    mealChips
                        .padding(.top, 16)
                        .padding(.bottom, 20)

                    // MARK: - Recommendations
                    if !recommendations.isEmpty {
                        sectionHeader("Recommended for you")
                        recommendationCards
                            .padding(.bottom, 24)
                    }

                    divider

                    // MARK: - Expiring Soon
                    if !expiringItems.isEmpty {
                        sectionHeader("Expiring soon")
                            .padding(.top, 20)
                        expiringList
                    }
                }
            }
            .background(.white)
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .onAppear { loadData() }
            .onChange(of: selectedMeal) { _, _ in loadRecommendations() }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack(alignment: .topLeading) {
            // Warm gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.95, blue: 0.92),
                    Color(red: 0.95, green: 0.91, blue: 0.88)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 220)

            VStack(alignment: .leading, spacing: 6) {
                Text(mealTimeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Hello, \(userName) 👋")
                    .font(.system(size: 26, weight: .bold))

                Text("What are we\neating today?")
                    .font(.system(size: 26, weight: .bold))
                    .lineSpacing(4)

                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray)
                    Text("Search recipes, ingredients...")
                        .foregroundStyle(.gray.opacity(0.6))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.top, 54)
        }
    }

    // MARK: - Meal Chips

    private var mealChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                mealChip("🌅 Breakfast", scene: .breakfast)
                mealChip("☀️ Lunch", scene: .mainMeal)
                mealChip("🌙 Dinner", scene: .lateNight)
                mealChip("🍵 Snack", scene: .snack)
            }
            .padding(.horizontal, 24)
        }
    }

    private func mealChip(_ label: String, scene: MealScene) -> some View {
        let isSelected = selectedMeal == scene
        return Button {
            selectedMeal = selectedMeal == scene ? nil : scene
        } label: {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? .black : .white)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color(.systemGray4), lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recommendation Cards

    private var recommendationCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(recommendations.prefix(6), id: \.recipe.id) { scored in
                    NavigationLink(value: scored.recipe) {
                        RecommendCard(scored: scored)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Expiring List

    private var expiringList: some View {
        VStack(spacing: 0) {
            ForEach(expiringItems.prefix(5)) { item in
                HStack(spacing: 12) {
                    Text(emojiForCategory(item.category))
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline.weight(.medium))
                        Text(expiryLabel(item))
                            .font(.caption)
                            .foregroundStyle(item.isExpired ? .red : (item.isExpiringSoon ? Color(red: 0.95, green: 0.22, blue: 0.24) : .secondary))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.gray.opacity(0.5))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: 1)
            .padding(.horizontal, 24)
    }

    private var mealTimeLabel: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 10 { return "Breakfast time" }
        if hour < 14 { return "Lunch time" }
        if hour < 17 { return "Afternoon" }
        return "Dinner time"
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

    private func expiryLabel(_ item: FridgeItem) -> String {
        guard let date = item.expirationDate else { return "" }
        if item.isExpired { return "Expired" }
        let days = Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "Tomorrow" }
        return "In \(days) days"
    }

    // MARK: - Data Loading

    private func loadData() {
        loadRecommendations()
        loadExpiringItems()
        loadUserName()
    }

    private func loadRecommendations() {
        let fridgeDescriptor = FetchDescriptor<FridgeItem>()
        let recipeDescriptor = FetchDescriptor<Recipe>()
        let recordDescriptor = FetchDescriptor<MealRecord>()
        let profileDescriptor = FetchDescriptor<UserProfile>()

        guard
            let fridgeItems = try? context.fetch(fridgeDescriptor),
            let recipes = try? context.fetch(recipeDescriptor)
        else { return }

        let records = (try? context.fetch(recordDescriptor)) ?? []
        let profile = (try? context.fetch(profileDescriptor))?.first

        let remaining: Int? = if selectedMeal == .breakfast {
            nil
        } else {
            profile.map { CalorieCalculator.remainingCalories(target: $0.dailyCalorieTarget, consumed: records) }
        }

        var filters = RecommendationFilters()
        filters.scene = selectedMeal
        filters.minimumMatchRatio = 0.3

        recommendations = RecommendationService.recommend(
            recipes: recipes,
            fridgeItems: fridgeItems,
            remainingCalories: remaining,
            filters: filters
        )
    }

    private func loadExpiringItems() {
        let descriptor = FetchDescriptor<FridgeItem>(
            sortBy: [SortDescriptor(\.expirationDate)]
        )
        let all = (try? context.fetch(descriptor)) ?? []
        expiringItems = all.filter { $0.isExpiringSoon || $0.isExpired }
    }

    private func loadUserName() {
        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = (try? context.fetch(descriptor))?.first {
            userName = "there"
        }
    }
}

// MARK: - Recommendation Card

private struct RecommendCard: View {
    let scored: RecommendationService.ScoredRecipe

    private var cardColor: Color {
        let scenes = scored.recipe.scenes
        if scenes.contains(.breakfast) { return Color(red: 1, green: 0.95, blue: 0.90) }
        if scenes.contains(.dessert) { return Color(red: 0.97, green: 0.92, blue: 0.97) }
        if scenes.contains(.drink) { return Color(red: 0.90, green: 0.95, blue: 1) }
        return Color(red: 0.92, green: 0.97, blue: 0.93)
    }

    private var emoji: String {
        let scenes = scored.recipe.scenes
        if scenes.contains(.breakfast) { return "🍳" }
        if scenes.contains(.dessert) { return "🍰" }
        if scenes.contains(.drink) { return "🥤" }
        if scenes.contains(.mainMeal) { return "🥘" }
        if scenes.contains(.snack) { return "🥜" }
        return "🍽️"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Emoji + match badge
            HStack {
                Text(emoji)
                    .font(.system(size: 36))
                Spacer()
                Text("\(Int(scored.matchRatio * 100))%")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.8))
                    .clipShape(Capsule())
            }
            .padding(.bottom, 40)

            Text(scored.recipe.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .padding(.bottom, 4)

            HStack(spacing: 4) {
                if let cal = scored.recipe.caloriesPerServing {
                    Text("\(cal) kcal")
                }
                if scored.recipe.totalTimeMinutes > 0 {
                    Text("· \(scored.recipe.totalTimeMinutes) min")
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
