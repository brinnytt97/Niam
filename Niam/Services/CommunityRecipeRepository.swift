import Foundation
import Supabase

// MARK: - Community Recipe Model (Decodable from Supabase)

struct CommunityRecipe: Decodable, Identifiable {
    let id: UUID
    let authorId: UUID
    let authorName: String
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
    let likesCount: Int
    let savesCount: Int
    let createdAt: Date

    var totalTimeMinutes: Int { prepTimeMinutes + cookTimeMinutes }

    enum CodingKeys: String, CodingKey {
        case id, title, cuisine, scenes, steps, notes, servings
        case authorId = "author_id"
        case authorName = "author_name"
        case mainIngredients = "main_ingredients"
        case sideIngredients = "side_ingredients"
        case seasonings
        case prepTimeMinutes = "prep_time_minutes"
        case cookTimeMinutes = "cook_time_minutes"
        case caloriesPerServing = "calories_per_serving"
        case likesCount = "likes_count"
        case savesCount = "saves_count"
        case createdAt = "created_at"
    }
}

// MARK: - Publish Payload (Encodable to Supabase)

private struct PublishPayload: Encodable {
    let authorId: UUID
    let authorName: String
    let title: String
    let cuisine: String
    let scenes: [String]
    let mainIngredients: [[String: AnyEncodable]]
    let sideIngredients: [[String: AnyEncodable]]
    let seasonings: [[String: AnyEncodable]]
    let steps: [String]
    let notes: String
    let servings: Int?
    let prepTimeMinutes: Int
    let cookTimeMinutes: Int
    let caloriesPerServing: Int?

    enum CodingKeys: String, CodingKey {
        case authorId = "author_id"
        case authorName = "author_name"
        case title, cuisine, scenes, steps, notes, servings
        case mainIngredients = "main_ingredients"
        case sideIngredients = "side_ingredients"
        case seasonings
        case prepTimeMinutes = "prep_time_minutes"
        case cookTimeMinutes = "cook_time_minutes"
        case caloriesPerServing = "calories_per_serving"
    }
}

/// Type-erasing Encodable wrapper for mixed-type dictionary values
struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        _encode = { encoder in try value.encode(to: encoder) }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

// MARK: - Repository

@MainActor
final class CommunityRecipeRepository: ObservableObject {
    static let shared = CommunityRecipeRepository()

    @Published private(set) var communityRecipes: [CommunityRecipe] = []
    @Published private(set) var isLoading = false

    private init() {}

    // MARK: - Fetch

    func fetch(limit: Int = 50) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let response = try await supabase
                .from("published_recipes")
                .select()
                .eq("is_visible", value: true)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
            communityRecipes = try decoder.decode([CommunityRecipe].self, from: response.data)
        } catch {
            print("[Community] fetch error: \(error)")
        }
    }

    // MARK: - Publish (NM-97)

    /// Publishes a local Recipe to the community feed.
    /// Returns the new Supabase UUID so the caller can store it on the local Recipe.
    func publish(_ recipe: Recipe) async throws -> UUID {
        guard let user = try? await supabase.auth.session.user else {
            throw CommunityError.notSignedIn
        }

        let authorName = user.userMetadata["full_name"]?.stringValue
            ?? user.email
            ?? "Anonymous"

        let payload = PublishPayload(
            authorId: user.id,
            authorName: authorName,
            title: recipe.title,
            cuisine: recipe.cuisine.rawValue,
            scenes: recipe.scenes.map(\.rawValue),
            mainIngredients: recipe.mainIngredients.map { ingredientDict($0) },
            sideIngredients: recipe.sideIngredients.map { ingredientDict($0) },
            seasonings: recipe.seasonings.map { ingredientDict($0) },
            steps: recipe.steps,
            notes: recipe.notes,
            servings: recipe.servings,
            prepTimeMinutes: recipe.prepTimeMinutes,
            cookTimeMinutes: recipe.cookTimeMinutes,
            caloriesPerServing: recipe.caloriesPerServing
        )

        struct InsertResult: Decodable { let id: UUID }

        let response = try await supabase
            .from("published_recipes")
            .insert(payload)
            .select("id")
            .single()
            .execute()

        let result = try JSONDecoder().decode(InsertResult.self, from: response.data)
        return result.id
    }

    // MARK: - Unpublish (NM-98)

    /// Soft-deletes by setting is_visible = false. Only works for the recipe's author.
    func unpublish(publishedRecipeID: UUID) async throws {
        guard (try? await supabase.auth.session) != nil else {
            throw CommunityError.notSignedIn
        }

        try await supabase
            .from("published_recipes")
            .update(["is_visible": false])
            .eq("id", value: publishedRecipeID.uuidString)
            .execute()
    }

    // MARK: - Save community recipe as local copy (NM-106)

    func toLocalRecipe(_ community: CommunityRecipe) -> Recipe {
        let cuisine = Cuisine(rawValue: community.cuisine) ?? .other
        let scenes = community.scenes.compactMap { MealScene(rawValue: $0) }
        let main = community.mainIngredients.map {
            Ingredient(name: $0.name, quantity: $0.quantity, unit: FoodUnit(rawValue: $0.unit) ?? .gram)
        }
        let side = community.sideIngredients.map {
            Ingredient(name: $0.name, quantity: $0.quantity, unit: FoodUnit(rawValue: $0.unit) ?? .gram)
        }
        let season = community.seasonings.map {
            Ingredient(name: $0.name, quantity: $0.quantity, unit: FoodUnit(rawValue: $0.unit) ?? .gram)
        }
        return Recipe(
            title: community.title,
            cuisine: cuisine,
            scenes: scenes.isEmpty ? [.mainMeal] : scenes,
            mainIngredients: main,
            sideIngredients: side,
            seasonings: season,
            steps: community.steps,
            notes: community.notes,
            servings: community.servings,
            prepTimeMinutes: community.prepTimeMinutes,
            cookTimeMinutes: community.cookTimeMinutes,
            caloriesPerServing: community.caloriesPerServing
        )
    }

    // MARK: - Helpers

    private func ingredientDict(_ ing: Ingredient) -> [String: AnyEncodable] {
        [
            "name": AnyEncodable(ing.name),
            "quantity": AnyEncodable(ing.quantity),
            "unit": AnyEncodable(ing.unit.rawValue)
        ]
    }
}

enum CommunityError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn: "Sign in with Apple to share recipes with the community."
        }
    }
}
