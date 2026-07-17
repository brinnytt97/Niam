import Foundation
import SwiftData

@Model
final class Recipe {
    var title: String
    var summary: String
    var ingredients: [Ingredient]
    var steps: [String]
    var servings: Int
    var prepTimeMinutes: Int
    var cookTimeMinutes: Int
    var caloriesPerServing: Int?
    var tags: [String]
    var isFavorite: Bool
    var imageData: Data?
    var createdDate: Date

    init(
        title: String,
        summary: String = "",
        ingredients: [Ingredient] = [],
        steps: [String] = [],
        servings: Int = 2,
        prepTimeMinutes: Int = 0,
        cookTimeMinutes: Int = 0,
        caloriesPerServing: Int? = nil,
        tags: [String] = [],
        isFavorite: Bool = false,
        imageData: Data? = nil
    ) {
        self.title = title
        self.summary = summary
        self.ingredients = ingredients
        self.steps = steps
        self.servings = servings
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.caloriesPerServing = caloriesPerServing
        self.tags = tags
        self.isFavorite = isFavorite
        self.imageData = imageData
        self.createdDate = .now
    }

    var totalTimeMinutes: Int {
        prepTimeMinutes + cookTimeMinutes
    }
}

struct Ingredient: Codable, Hashable {
    var name: String
    var quantity: Double
    var unit: FoodUnit
}
