import SwiftUI

struct AddFridgeItemView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var quantity: Double = 1
    @State private var unit: FoodUnit = .piece
    @State private var category: FoodCategory = .other
    @State private var hasExpiration = false
    @State private var expirationDate = Calendar.current.date(byAdding: .day, value: 7, to: .now)!
    @State private var notes = ""
    @State private var shelfLifeHint: String?

    var onSave: (FridgeItem) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $name)
                        .onChange(of: name) { _, newValue in
                            autoFillFromShelfLife(newValue)
                        }

                    // Show shelf life hint if matched
                    if let hint = shelfLifeHint {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            Text(hint)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        TextField("Quantity", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $unit) {
                            ForEach(FoodUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                    }
                    Picker("Category", selection: $category) {
                        ForEach(FoodCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }

                Section("Expiration") {
                    Toggle("Has Expiration Date", isOn: $hasExpiration)
                    if hasExpiration {
                        DatePicker("Expires", selection: $expirationDate, displayedComponents: .date)
                    }
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let item = FridgeItem(
                            name: name,
                            quantity: quantity,
                            unit: unit,
                            category: category,
                            expirationDate: hasExpiration ? expirationDate : nil,
                            notes: notes
                        )
                        onSave(item)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func autoFillFromShelfLife(_ ingredientName: String) {
        guard ingredientName.count >= 1 else {
            shelfLifeHint = nil
            return
        }

        if let days = ShelfLifeService.estimatedDays(for: ingredientName) {
            // Auto-enable expiration and set date
            hasExpiration = true
            expirationDate = Calendar.current.date(byAdding: .day, value: days, to: .now)!

            // Show hint
            if days >= 365 {
                shelfLifeHint = "Shelf life: ~\(days / 365) year(s)"
            } else {
                shelfLifeHint = "Shelf life: ~\(days) days (auto-set)"
            }

            // Auto-set category
            if let suggestedCategory = ShelfLifeService.suggestedCategory(for: ingredientName) {
                category = suggestedCategory
            }
        } else {
            shelfLifeHint = nil
        }
    }
}
