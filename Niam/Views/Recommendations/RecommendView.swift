import SwiftUI
import SwiftData

struct RecommendView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel: RecommendViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    RecommendContent(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Recommendations")
            .onAppear {
                if viewModel == nil {
                    viewModel = RecommendViewModel(context: context)
                    viewModel?.generateRecommendations()
                }
            }
        }
    }
}

private struct RecommendContent: View {
    @Bindable var viewModel: RecommendViewModel

    var body: some View {
        List {
            // MARK: - Meal Picker
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        MealChip(
                            title: "All",
                            isSelected: viewModel.selectedMeal == nil
                        ) {
                            viewModel.selectedMeal = nil
                            viewModel.generateRecommendations()
                        }
                        ForEach(MealScene.allCases, id: \.self) { scene in
                            MealChip(
                                title: scene.rawValue,
                                isSelected: viewModel.selectedMeal == scene
                            ) {
                                viewModel.selectedMeal = scene
                                viewModel.generateRecommendations()
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // MARK: - Filters
            Section {
                HStack {
                    Text("Min Match")
                    Slider(value: $viewModel.filters.minimumMatchRatio, in: 0...1, step: 0.1)
                    Text("\(Int(viewModel.filters.minimumMatchRatio * 100))%")
                        .frame(width: 40)
                }

                Button("Refresh") {
                    viewModel.generateRecommendations()
                }
            }

            // MARK: - Results
            if viewModel.recommendations.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Recommendations",
                        systemImage: "sparkles",
                        description: Text("Add ingredients to your fridge and recipes to get started")
                    )
                }
            } else {
                Section("Matches (\(viewModel.recommendations.count))") {
                    ForEach(viewModel.recommendations, id: \.recipe.id) { scored in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(scored.recipe.title)
                                    .font(.headline)
                                Spacer()
                                Text("\(Int(scored.matchRatio * 100))% match")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(matchColor(scored.matchRatio).opacity(0.2))
                                    .foregroundStyle(matchColor(scored.matchRatio))
                                    .clipShape(Capsule())
                            }

                            HStack(spacing: 8) {
                                ForEach(scored.recipe.scenes.prefix(2), id: \.self) { scene in
                                    Text(scene.rawValue)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.orange.opacity(0.15))
                                        .foregroundStyle(.orange)
                                        .clipShape(Capsule())
                                }

                                if let cal = scored.recipe.caloriesPerServing {
                                    Label("\(cal) kcal", systemImage: "flame")
                                        .font(.caption)
                                    if scored.caloriesFit {
                                        Label("Fits budget", systemImage: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                }
                            }

                            if !scored.missingIngredients.isEmpty {
                                Text("Missing: \(scored.missingIngredients.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private func matchColor(_ ratio: Double) -> Color {
        if ratio >= 0.8 { return .green }
        if ratio >= 0.5 { return .orange }
        return .red
    }
}

private struct MealChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
