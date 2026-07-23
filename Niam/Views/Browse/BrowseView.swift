import SwiftUI
import SwiftData

struct BrowseView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedMeal: MealScene? = nil
    @State private var showingSearch = false
    @State private var recommendations: [RecommendationService.ScoredRecipe] = []
    @State private var expiringItems: [FridgeItem] = []
    @State private var editingFridgeItem: FridgeItem?
    @State private var userName = "there"
    @State private var caloriesConsumed = 0
    @State private var caloriesTarget = 2000
    @State private var selectedOfficialRecipe: OfficialRecipe?

    @StateObject private var officialService = OfficialRecipeService.shared
    @StateObject private var healthKit = HealthKitService.shared

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

                    // MARK: - Content
                    if recommendations.isEmpty && expiringItems.isEmpty {
                        // Empty state: guide new users
                        emptyStateGuide
                    } else {
                        // Recommendations
                        if !recommendations.isEmpty {
                            sectionHeader("Guess you like")
                            recommendationCards
                                .padding(.bottom, 24)
                        }

                        divider

                        // Expiring Soon
                        if !expiringItems.isEmpty {
                            sectionHeader("Expiring soon")
                                .padding(.top, 20)
                            expiringList
                        }
                    }

                    // MARK: - Official Recipes
                    let filtered = officialService.recipes(for: selectedMeal)
                    if !filtered.isEmpty {
                        divider.padding(.top, 20)
                        sectionHeader("Discover")
                            .padding(.top, 20)
                        officialRecipeCards(filtered)
                            .padding(.bottom, 24)
                    } else if officialService.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 32)
                    }
                }
            }
            .background(.white)
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .sheet(isPresented: $showingSearch) {
                BrowseSearchView()
            }
            .sheet(item: $editingFridgeItem) { item in
                AddFridgeItemView(editingItem: item) { _ in
                    try? context.save()
                    loadExpiringItems()
                }
            }
            .onAppear {
                Task {
                    await healthKit.requestAuthorizationIfNeeded()
                    loadData()
                }
                Task { await officialService.fetchIfNeeded() }
            }
            .onChange(of: selectedMeal) { _, _ in loadRecommendations() }
            .sheet(item: $selectedOfficialRecipe) { recipe in
                OfficialRecipeDetailView(recipe: recipe) { local in
                    print("[BrowseView] inserting recipe: \(local.title)")
                    context.insert(local)
                    do {
                        try context.save()
                        print("[BrowseView] save succeeded")
                        let descriptor = FetchDescriptor<Recipe>()
                        let count = (try? context.fetch(descriptor))?.count ?? -1
                        print("[BrowseView] total recipes in context: \(count)")
                    } catch {
                        print("[BrowseView] save FAILED: \(error)")
                    }
                }
            }
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

                Text("Hello, \(userName)")
                    .font(.system(size: 26, weight: .bold))

                Text("What's on the menu today?")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.secondary)

                // Calorie summary
                HStack(spacing: 8) {
                    let remaining = max(0, caloriesTarget - caloriesConsumed)
                    let progress = Double(caloriesConsumed) / Double(max(1, caloriesTarget))

                    Circle()
                        .trim(from: 0, to: min(1, progress))
                        .stroke(
                            progress > 1 ? Color.red : Color.green,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemGray5), lineWidth: 3)
                        )

                    Text("\(remaining) kcal remaining")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)

                // Search bar (tappable)
                Button { showingSearch = true } label: {
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
                }
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
                .contentShape(Rectangle())
                .onTapGesture { editingFridgeItem = item }
            }
        }
    }

    // MARK: - Empty State Guide

    private var emptyStateGuide: some View {
        VStack(spacing: 12) {
            guideCard(
                emoji: "🍳",
                title: "Add your first recipe",
                subtitle: "Start building your recipe collection"
            )
            guideCard(
                emoji: "🧊",
                title: "Stock your kitchen",
                subtitle: "Tell us what ingredients you have"
            )
            guideCard(
                emoji: "📊",
                title: "Set up your profile",
                subtitle: "Get personalized calorie targets"
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private func guideCard(emoji: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Text(emoji)
                .font(.system(size: 32))
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.gray.opacity(0.4))
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Official Recipe Cards

    private func officialRecipeCards(_ recipes: [OfficialRecipe]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(recipes.prefix(12)) { recipe in
                    Button { selectedOfficialRecipe = recipe } label: {
                        OfficialRecipeCard(recipe: recipe)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
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
        loadCalorieSummary()
    }

    private func loadCalorieSummary() {
        let recordDescriptor = FetchDescriptor<MealRecord>()
        let profileDescriptor = FetchDescriptor<UserProfile>()
        let records = (try? context.fetch(recordDescriptor)) ?? []
        let profile = (try? context.fetch(profileDescriptor))?.first
        caloriesConsumed = CalorieCalculator.totalCalories(consumed: records)
        let baseTarget = profile?.dailyCalorieTarget ?? 2000
        caloriesTarget = baseTarget + healthKit.exerciseCaloriesToday
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

        let preferences = RecommendationService.analyzePreferences(recipes: recipes)

        recommendations = RecommendationService.recommend(
            recipes: recipes,
            fridgeItems: fridgeItems,
            remainingCalories: remaining,
            filters: filters,
            preferences: preferences
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
            userName = profile.displayName
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
                Text("\(Int(scored.score * 100))%")
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
