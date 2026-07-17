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
            Section {
                HStack {
                    Text("Min Match")
                    Slider(value: $viewModel.filters.minimumMatchRatio, in: 0...1, step: 0.1)
                    Text("\(Int(viewModel.filters.minimumMatchRatio * 100))%")
                        .frame(width: 40)
                }

                Button("Refresh Recommendations") {
                    viewModel.generateRecommendations()
                }
            }

            if viewModel.recommendations.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Recommendations",
                        systemImage: "sparkles",
                        description: Text("Add ingredients to your fridge and recipes to get started")
                    )
                }
            } else {
                Section("Based on Your Fridge (\(viewModel.recommendations.count))") {
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

                            if let cal = scored.recipe.caloriesPerServing {
                                HStack {
                                    Label("\(cal) kcal", systemImage: "flame")
                                    if scored.caloriesFit {
                                        Label("Fits budget", systemImage: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    } else {
                                        Label("Over budget", systemImage: "exclamationmark.circle")
                                            .foregroundStyle(.orange)
                                    }
                                }
                                .font(.caption)
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
