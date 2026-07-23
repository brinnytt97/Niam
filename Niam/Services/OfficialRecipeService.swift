import Foundation

@MainActor
final class OfficialRecipeService: ObservableObject {
    static let shared = OfficialRecipeService()

    @Published private(set) var recipes: [OfficialRecipe] = []
    @Published private(set) var isLoading = false

    private var hasFetched = false

    func fetchIfNeeded() async {
        guard !hasFetched else { return }
        await fetch()
    }

    func fetch() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await supabase
                .from("official_recipes")
                .select()
                .order("created_at")
                .execute()
            recipes = try JSONDecoder().decode([OfficialRecipe].self, from: response.data)
            hasFetched = true
        } catch {
            print("[OfficialRecipeService] fetch error: \(error)")
        }
    }

    func recipes(for scene: MealScene?) -> [OfficialRecipe] {
        guard let scene else { return recipes }
        return recipes.filter { $0.scenes.contains(scene.rawValue) }
    }
}
