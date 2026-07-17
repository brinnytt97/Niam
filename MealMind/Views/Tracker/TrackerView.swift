import SwiftUI
import SwiftData

struct TrackerView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel: TrackerViewModel?
    @State private var showingAddMeal = false
    @State private var showingProfile = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    TrackerContent(viewModel: vm)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Calorie Tracker")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddMeal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealRecordView { record in
                    viewModel?.addRecord(record)
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView(existingProfile: viewModel?.profile) { profile in
                    viewModel?.saveProfile(profile)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = TrackerViewModel(context: context)
                }
            }
        }
    }
}

private struct TrackerContent: View {
    @Bindable var viewModel: TrackerViewModel

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    HStack {
                        CalorieSummaryCard(
                            title: "Consumed",
                            value: viewModel.totalCaloriesToday,
                            color: .orange
                        )
                        CalorieSummaryCard(
                            title: "Remaining",
                            value: viewModel.remainingCalories,
                            color: .green
                        )
                        CalorieSummaryCard(
                            title: "Target",
                            value: viewModel.dailyTarget,
                            color: .blue
                        )
                    }

                    ProgressView(value: Double(viewModel.totalCaloriesToday), total: Double(viewModel.dailyTarget))
                        .tint(viewModel.totalCaloriesToday > viewModel.dailyTarget ? .red : .green)
                }
                .padding(.vertical, 8)
            }

            Section("Macros") {
                HStack {
                    MacroLabel(name: "Protein", value: viewModel.macros.protein, unit: "g", color: .red)
                    Spacer()
                    MacroLabel(name: "Carbs", value: viewModel.macros.carbs, unit: "g", color: .blue)
                    Spacer()
                    MacroLabel(name: "Fat", value: viewModel.macros.fat, unit: "g", color: .yellow)
                }
            }

            Section("Today's Meals") {
                ForEach(viewModel.todayRecords) { record in
                    MealRecordRow(record: record)
                }
                .onDelete { offsets in
                    for index in offsets {
                        viewModel.deleteRecord(viewModel.todayRecords[index])
                    }
                }

                if viewModel.todayRecords.isEmpty {
                    Text("No meals recorded yet")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct CalorieSummaryCard: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.title2.bold())
                .foregroundStyle(color)
            Text("kcal")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MacroLabel: View {
    let name: String
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value, specifier: "%.1f")\(unit)")
                .font(.subheadline.bold())
                .foregroundStyle(color)
        }
    }
}

private struct MealRecordRow: View {
    let record: MealRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.name)
                    .font(.headline)
                Text(record.mealType.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(record.calories) kcal")
                .font(.subheadline)
                .foregroundStyle(.orange)
        }
    }
}
