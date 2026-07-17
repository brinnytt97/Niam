import SwiftUI
import PhotosUI

struct AddRecipeView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var cuisine: Cuisine = .chinese
    @State private var selectedScenes: Set<MealScene> = [.mainMeal]
    @State private var servingsText = ""
    @State private var prepTime = 0
    @State private var prepTimeText = ""
    @State private var cookTime = 0
    @State private var cookTimeText = ""
    @State private var caloriesText = ""
    @State private var notes = ""

    @State private var mainIngredients: [Ingredient] = []
    @State private var sideIngredients: [Ingredient] = []
    @State private var seasonings: [Ingredient] = []
    @State private var steps: [String] = []

    @State private var newIngName = ""
    @State private var newIngQty: Double = 1
    @State private var newIngUnit: FoodUnit = .gram
    @State private var addingTo: IngredientSection = .main

    @State private var newStep = ""

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
                }

                // MARK: - Scene (multi-select horizontal scroll)
                Section("Scene") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MealScene.allCases, id: \.self) { scene in
                                Button {
                                    if selectedScenes.contains(scene) {
                                        selectedScenes.remove(scene)
                                    } else {
                                        selectedScenes.insert(scene)
                                    }
                                } label: {
                                    Text(scene.rawValue)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedScenes.contains(scene)
                                                ? Color.accentColor
                                                : Color(.systemGray5)
                                        )
                                        .foregroundStyle(
                                            selectedScenes.contains(scene) ? .white : .primary
                                        )
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                // MARK: - Details
                Section("Details") {
                    HStack {
                        Text("Servings")
                        Spacer()
                        TextField("Optional", text: $servingsText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    // Prep time: editable text + stepper
                    HStack {
                        Text("Prep")
                        Spacer()
                        TextField("min", text: $prepTimeText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .onChange(of: prepTimeText) { _, val in
                                prepTime = Int(val) ?? 0
                            }
                        Text("min")
                            .foregroundStyle(.secondary)
                        Stepper("", value: $prepTime, in: 0...600, step: 5)
                            .labelsHidden()
                            .onChange(of: prepTime) { _, val in
                                prepTimeText = val > 0 ? String(val) : ""
                            }
                    }

                    // Cook time: editable text + stepper
                    HStack {
                        Text("Cook")
                        Spacer()
                        TextField("min", text: $cookTimeText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .onChange(of: cookTimeText) { _, val in
                                cookTime = Int(val) ?? 0
                            }
                        Text("min")
                            .foregroundStyle(.secondary)
                        Stepper("", value: $cookTime, in: 0...600, step: 5)
                            .labelsHidden()
                            .onChange(of: cookTime) { _, val in
                                cookTimeText = val > 0 ? String(val) : ""
                            }
                    }

                    HStack {
                        Text("Calories/serving")
                        Spacer()
                        TextField("kcal", text: $caloriesText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                // MARK: - Ingredients
                ingredientSection(title: "Main Ingredients", items: $mainIngredients, section: .main)
                ingredientSection(title: "Side Ingredients", items: $sideIngredients, section: .side)
                ingredientSection(title: "Seasonings", items: $seasonings, section: .seasoning)

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
                            scenes: Array(selectedScenes),
                            mainIngredients: mainIngredients,
                            sideIngredients: sideIngredients,
                            seasonings: seasonings,
                            steps: steps,
                            notes: notes,
                            servings: Int(servingsText),
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
