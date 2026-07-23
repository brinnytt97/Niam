import SwiftUI
import PhotosUI
import UIKit

struct AddRecipeView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var showingPasteResult = false
    @State private var pasteError = false
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

    /// If set, we are editing an existing recipe
    var editingRecipe: Recipe?
    var onSave: (Recipe) -> Void

    init(editingRecipe: Recipe? = nil, onSave: @escaping (Recipe) -> Void) {
        self.editingRecipe = editingRecipe
        self.onSave = onSave

        if let r = editingRecipe {
            _title = State(initialValue: r.title)
            _cuisine = State(initialValue: r.cuisine)
            _selectedScenes = State(initialValue: Set(r.scenes))
            _servingsText = State(initialValue: r.servings.map { String($0) } ?? "")
            _prepTime = State(initialValue: r.prepTimeMinutes)
            _prepTimeText = State(initialValue: r.prepTimeMinutes > 0 ? String(r.prepTimeMinutes) : "")
            _cookTime = State(initialValue: r.cookTimeMinutes)
            _cookTimeText = State(initialValue: r.cookTimeMinutes > 0 ? String(r.cookTimeMinutes) : "")
            _caloriesText = State(initialValue: r.caloriesPerServing.map { String($0) } ?? "")
            _notes = State(initialValue: r.notes)
            _mainIngredients = State(initialValue: r.mainIngredients)
            _sideIngredients = State(initialValue: r.sideIngredients)
            _seasonings = State(initialValue: r.seasonings)
            _steps = State(initialValue: r.steps)
            _imageData = State(initialValue: r.imageData)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Title & Cuisine
                Section("Recipe") {
                    TextField("Recipe Title", text: $title)
                    Picker("Cuisine", selection: $cuisine) {
                        ForEach(Cuisine.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                }

                // MARK: - Scene
                Section {
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
                } header: {
                    Text("Scene")
                }

                // MARK: - Time
                Section {
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
                } header: {
                    Text("Time")
                } footer: {
                    Text("Prep includes washing, cutting, marinating, chilling, fermenting, and resting time.")
                }

                // MARK: - Main Ingredients
                ingredientSection(
                    title: "Main Ingredients",
                    subtitle: "Core ingredients that define the dish.",
                    items: $mainIngredients,
                    section: .main
                )

                // MARK: - Side Ingredients
                ingredientSection(
                    title: "Side Ingredients",
                    subtitle: "Visible in the dish — adds texture, color, or aroma. Fresh scallion, ginger, garlic, chili, and herbs go here.",
                    items: $sideIngredients,
                    section: .side
                )

                // MARK: - Seasonings
                ingredientSection(
                    title: "Seasonings",
                    subtitle: "Salt, sugar, soy sauce, vinegar, cooking wine, oil, sauces, and ground spices.",
                    items: $seasonings,
                    section: .seasoning
                )

                // MARK: - Servings & Calories
                Section("Servings & Calories") {
                    HStack {
                        Text("Servings")
                        Spacer()
                        TextField("Optional", text: $servingsText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
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

                // MARK: - Photo (optional, at the end)
                Section {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Label("Add Photo", systemImage: "camera")
                                .frame(maxWidth: .infinity, minHeight: 80)
                                .background(.fill.tertiary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            imageData = try? await newItem?.loadTransferable(type: Data.self)
                        }
                    }
                } header: {
                    Text("Photo")
                } footer: {
                    Text("Optional. Add a photo of the finished dish.")
                }
            }
            .navigationTitle(editingRecipe != nil ? "Edit Recipe" : "New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if editingRecipe == nil {
                    ToolbarItem(placement: .secondaryAction) {
                        Button {
                            smartPaste()
                        } label: {
                            Label("Smart Paste", systemImage: "doc.on.clipboard")
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let existing = editingRecipe {
                            // Update existing recipe in place
                            existing.title = title
                            existing.cuisine = cuisine
                            existing.scenes = Array(selectedScenes)
                            existing.mainIngredients = mainIngredients
                            existing.sideIngredients = sideIngredients
                            existing.seasonings = seasonings
                            existing.steps = steps
                            existing.notes = notes
                            existing.servings = Int(servingsText)
                            existing.prepTimeMinutes = prepTime
                            existing.cookTimeMinutes = cookTime
                            existing.caloriesPerServing = Int(caloriesText)
                            existing.imageData = imageData
                            onSave(existing)
                        } else {
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
                        }
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func smartPaste() {
        guard let text = UIPasteboard.general.string, !text.isEmpty else { return }
        guard let parsed = RecipePasteParser.parse(text) else { return }

        if !parsed.title.isEmpty { title = parsed.title }
        cuisine = parsed.cuisine
        selectedScenes = parsed.scenes
        mainIngredients = parsed.mainIngredients
        sideIngredients = parsed.sideIngredients
        seasonings = parsed.seasonings
        steps = parsed.steps
        notes = parsed.notes
        if let s = parsed.servings { servingsText = String(s) }
        if parsed.prepTimeMinutes > 0 {
            prepTime = parsed.prepTimeMinutes
            prepTimeText = String(parsed.prepTimeMinutes)
        }
        if parsed.cookTimeMinutes > 0 {
            cookTime = parsed.cookTimeMinutes
            cookTimeText = String(parsed.cookTimeMinutes)
        }
        if let cal = parsed.caloriesPerServing { caloriesText = String(cal) }
    }

    private func ingredientSection(
        title: String,
        subtitle: String = "",
        items: Binding<[Ingredient]>,
        section: IngredientSection
    ) -> some View {
        Section {
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
        } header: {
            Text("\(title) (\(items.wrappedValue.count))")
        } footer: {
            if !subtitle.isEmpty {
                Text(subtitle)
            }
        }
    }
}

private enum IngredientSection {
    case main, side, seasoning
}
