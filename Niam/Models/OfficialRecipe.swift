import Foundation

struct OfficialRecipe: Decodable, Identifiable {
    let id: UUID
    let title: String
    let cuisine: String
    let scenes: [String]
    let mainIngredients: [RemoteIngredient]
    let sideIngredients: [RemoteIngredient]
    let seasonings: [RemoteIngredient]
    let steps: [String]
    let notes: String
    let servings: Int?
    let prepTimeMinutes: Int
    let cookTimeMinutes: Int
    let caloriesPerServing: Int?

    var totalTimeMinutes: Int { prepTimeMinutes + cookTimeMinutes }

    enum CodingKeys: String, CodingKey {
        case id, title, cuisine, scenes, steps, notes, servings
        case mainIngredients = "main_ingredients"
        case sideIngredients = "side_ingredients"
        case seasonings
        case prepTimeMinutes = "prep_time_minutes"
        case cookTimeMinutes = "cook_time_minutes"
        case caloriesPerServing = "calories_per_serving"
    }
}

struct RemoteIngredient: Decodable, Hashable {
    let name: String
    let quantity: Double
    let unit: String
}
