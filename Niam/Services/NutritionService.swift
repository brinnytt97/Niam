import Foundation

/// USDA FoodData Central API client
struct NutritionService {
    private static let baseURL = "https://api.nal.usda.gov/fdc/v1"
    // Free API key — register at https://fdc.nal.usda.gov/api-key-signup.html
    // Replace with your own key
    private static var apiKey: String {
        // TODO: Move to a config or keychain
        "DEMO_KEY"
    }

    struct SearchResult: Codable {
        let foods: [FoodItem]
    }

    struct FoodItem: Codable, Identifiable {
        let fdcId: Int
        let description: String
        let foodNutrients: [FoodNutrient]

        var id: Int { fdcId }

        var calories: Int? {
            foodNutrients.first { $0.nutrientName == "Energy" }.map { Int($0.value) }
        }

        var protein: Double? {
            foodNutrients.first { $0.nutrientName == "Protein" }?.value
        }

        var carbs: Double? {
            foodNutrients.first { $0.nutrientName == "Carbohydrate, by difference" }?.value
        }

        var fat: Double? {
            foodNutrients.first { $0.nutrientName == "Total lipid (fat)" }?.value
        }
    }

    struct FoodNutrient: Codable {
        let nutrientName: String
        let value: Double
    }

    static func search(query: String) async throws -> [FoodItem] {
        var components = URLComponents(string: "\(baseURL)/foods/search")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "pageSize", value: "10"),
            URLQueryItem(name: "dataType", value: "Foundation,SR Legacy")
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let result = try JSONDecoder().decode(SearchResult.self, from: data)
        return result.foods
    }
}
