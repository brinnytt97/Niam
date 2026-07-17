import Foundation
import SwiftData

@Model
final class Recipe {
    var title: String
    var cuisine: Cuisine
    var scene: MealScene
    var mainIngredients: [Ingredient]
    var sideIngredients: [Ingredient]
    var seasonings: [Ingredient]
    var steps: [String]
    var notes: String
    var servings: Int
    var prepTimeMinutes: Int
    var cookTimeMinutes: Int
    var caloriesPerServing: Int?
    var isFavorite: Bool
    var imageData: Data?
    var createdDate: Date

    init(
        title: String,
        cuisine: Cuisine = .chinese,
        scene: MealScene = .mainMeal,
        mainIngredients: [Ingredient] = [],
        sideIngredients: [Ingredient] = [],
        seasonings: [Ingredient] = [],
        steps: [String] = [],
        notes: String = "",
        servings: Int = 2,
        prepTimeMinutes: Int = 0,
        cookTimeMinutes: Int = 0,
        caloriesPerServing: Int? = nil,
        isFavorite: Bool = false,
        imageData: Data? = nil
    ) {
        self.title = title
        self.cuisine = cuisine
        self.scene = scene
        self.mainIngredients = mainIngredients
        self.sideIngredients = sideIngredients
        self.seasonings = seasonings
        self.steps = steps
        self.notes = notes
        self.servings = servings
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.caloriesPerServing = caloriesPerServing
        self.isFavorite = isFavorite
        self.imageData = imageData
        self.createdDate = .now
    }

    var totalTimeMinutes: Int {
        prepTimeMinutes + cookTimeMinutes
    }

    /// All ingredients combined for matching
    var allIngredients: [Ingredient] {
        mainIngredients + sideIngredients + seasonings
    }
}

struct Ingredient: Codable, Hashable {
    var name: String
    var quantity: Double
    var unit: FoodUnit
}

enum Cuisine: String, Codable, CaseIterable {
    case chinese = "Chinese"
    case japanese = "Japanese"
    case korean = "Korean"
    case thai = "Thai"
    case italian = "Italian"
    case french = "French"
    case mexican = "Mexican"
    case indian = "Indian"
    case american = "American"
    case mediterranean = "Mediterranean"
    case other = "Other"
}

enum MealScene: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case mainMeal = "Main Meal"
    case afternoonTea = "Afternoon Tea"
    case drink = "Drink"
    case dessert = "Dessert"
    case snack = "Snack"
    case lateNight = "Late Night"
}
