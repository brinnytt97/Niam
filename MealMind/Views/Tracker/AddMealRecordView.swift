import SwiftUI

struct AddMealRecordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var mealType: MealType = .lunch
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var notes = ""

    // Nutrition search
    @State private var searchResults: [NutritionService.FoodItem] = []
    @State private var isSearching = false

    var onSave: (MealRecord) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    TextField("Food name", text: $name)
                        .onSubmit { searchNutrition() }

                    if isSearching {
                        ProgressView("Searching USDA database...")
                    }

                    if !searchResults.isEmpty {
                        ForEach(searchResults) { food in
                            Button {
                                applyNutrition(food)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(food.description)
                                        .font(.subheadline)
                                    if let cal = food.calories {
                                        Text("\(cal) kcal")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }

                Section("Meal Type") {
                    Picker("Type", selection: $mealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Nutrition (per serving)") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("kcal", text: $calories)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Protein")
                        Spacer()
                        TextField("g", text: $protein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Carbs")
                        Spacer()
                        TextField("g", text: $carbs)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Fat")
                        Spacer()
                        TextField("g", text: $fat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2)
                }
            }
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let record = MealRecord(
                            name: name,
                            mealType: mealType,
                            calories: Int(calories) ?? 0,
                            protein: Double(protein) ?? 0,
                            carbs: Double(carbs) ?? 0,
                            fat: Double(fat) ?? 0,
                            notes: notes
                        )
                        onSave(record)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func searchNutrition() {
        guard !name.isEmpty else { return }
        isSearching = true
        Task {
            do {
                searchResults = try await NutritionService.search(query: name)
            } catch {
                searchResults = []
            }
            isSearching = false
        }
    }

    private func applyNutrition(_ food: NutritionService.FoodItem) {
        if let cal = food.calories { calories = String(cal) }
        if let p = food.protein { protein = String(format: "%.1f", p) }
        if let c = food.carbs { carbs = String(format: "%.1f", c) }
        if let f = food.fat { fat = String(format: "%.1f", f) }
        searchResults = []
    }
}
