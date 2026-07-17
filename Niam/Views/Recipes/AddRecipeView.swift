import SwiftUI
import PhotosUI

struct AddRecipeView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var cuisine: Cuisine = .chinese
    @State private var scene: MealScene = .mainMeal
    @State private var servings = 2
    @State private var prepTime = 10
    @State private var cookTime = 20
    @State private var caloriesText = ""
    @State private var notes = ""

    @State private var mainIngredients: [Ingredient] = []
    @State private var sideIngredients: [Ingredient] = []
    @State private var seasonings: [Ingredient] = []
    @State private var steps: [String] = []

    // New ingredient input
    @State private var newIngName = ""
    @State private var newIngQty: Double = 1
    @State private var newIngUnit: FoodUnit = .gram

    // New step input
    @State private var newStep = ""

    // Which ingredient section is being added to
    @State private var addingTo: IngredientSection = .main

    // Photo
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?

    var onSave: (Recipe) -> Void

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Photo
                Section {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Label("Add Photo", systemImage: "camera")
                                .frame(maxWidth: .infinity, minHeight: 100)
                                .background(.fill.tertiary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            imageData = try? await newItem?.loadTransferable(type: Data.self)
                        }
                    }
                }

                // MARK: - Basic Info
                Section("Basic Info") {
                    TextField("Recipe Title", text: $title)
                    Picker("Cuisine", selection: $cuisine) {
                        ForEach(Cuisine.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    Picker("Scene", selection: $scene) {
                        ForEach(MealScene.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    Stepper("Servings: \(servings)", value: $servings, in: 1...20)
                    Stepper("Prep: \(prepTime) min", value: $prepTime, in: 0...300, step: 5)
                    Stepper("Cook: \(cookTime) min", value: $cookTime, in: 0...300, step: 5)
                    TextField("Calories per serving", text: $caloriesText)
                        .keyboardType(.numberPad)
                }

                // MARK: - Main Ingredients
                ingredientSection(
                    title: "Main Ingredients",
                    items: $mainIngredients,
                    section: .main
                )

                // MARK: - Side Ingredients
                ingredientSection(
                    title: "Side Ingredients",
                    items: $sideIngredients,
                    section: .side
                )

                // MARK: - Seasonings
                ingredientSection(
                    title: "Seasonings",
                    items: $seasonings,
                    section: .seasoning
                )

                // MARK: - Steps
                Section("Steps (\(steps.count))") {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        Text("\(index + 1). \(step)")
                    }
                    .onDelete { steps.remove(atOffsets: $0) }
                    .onMove { steps.move(fromOffsets: $0, toOffset: $1) }

                    HStack {
                        TextField("Add a step...", text: $newStep)
                        Button {
                            guard !newStep.isEmpty else { return }
                            steps.append(newStep)
                            newStep = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }

                // MARK: - Notes
                Section("Notes") {
                    TextField("Optional notes...", text: $notes, axis: .vertical)
                        .lineLimit(4)
                }
            }
            .navigationTitle("New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let recipe = Recipe(
                            title: title,
                            cuisine: cuisine,
                            scene: scene,
                            mainIngredients: mainIngredients,
                            sideIngredients: sideIngredients,
                            seasonings: seasonings,
                            steps: steps,
                            notes: notes,
                            servings: servings,
                            prepTimeMinutes: prepTime,
                            cookTimeMinutes: cookTime,
                            caloriesPerServing: Int(caloriesText),
                            imageData: imageData
                        )
                        onSave(recipe)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func ingredientSection(
        title: String,
        items: Binding<[Ingredient]>,
        section: IngredientSection
    ) -> some View {
        Section("\(title) (\(items.wrappedValue.count))") {
            ForEach(items.wrappedValue, id: \.self) { ing in
                Text("\(ing.quantity, specifier: "%.1f") \(ing.unit.rawValue) \(ing.name)")
            }
            .onDelete { items.wrappedValue.remove(atOffsets: $0) }

            HStack {
                TextField("Name", text: section == addingTo ? $newIngName : .constant(""))
                    .onTapGesture { addingTo = section }
                TextField("Qty", value: section == addingTo ? $newIngQty : .constant(1), format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 50)
                    .onTapGesture { addingTo = section }
                Picker("", selection: section == addingTo ? $newIngUnit : .constant(.gram)) {
                    ForEach(FoodUnit.allCases, id: \.self) { u in
                        Text(u.rawValue).tag(u)
                    }
                }
                .frame(width: 70)
                Button {
                    addingTo = section
                    guard !newIngName.isEmpty else { return }
                    items.wrappedValue.append(Ingredient(
                        name: newIngName,
                        quantity: newIngQty,
                        unit: newIngUnit
                    ))
                    newIngName = ""
                    newIngQty = 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
    }
}

private enum IngredientSection {
    case main, side, seasoning
}
