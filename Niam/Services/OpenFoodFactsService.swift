import Foundation

/// Open Food Facts API client - free, no API key needed.
struct OpenFoodFactsService {

    struct Product: Codable {
        let productName: String?
        let brands: String?
        let nutriments: Nutriments?
        let imageUrl: String?

        enum CodingKeys: String, CodingKey {
            case productName = "product_name"
            case brands
            case nutriments
            case imageUrl = "image_url"
        }
    }

    struct Nutriments: Codable {
        let energyKcal100g: Double?
        let proteins100g: Double?
        let carbohydrates100g: Double?
        let fat100g: Double?

        enum CodingKeys: String, CodingKey {
            case energyKcal100g = "energy-kcal_100g"
            case proteins100g = "proteins_100g"
            case carbohydrates100g = "carbohydrates_100g"
            case fat100g = "fat_100g"
        }
    }

    struct APIResponse: Codable {
        let status: Int
        let product: Product?
    }

    /// Look up a product by barcode (EAN-13, UPC-A, etc.)
    static func lookup(barcode: String) async throws -> Product? {
        let urlString = "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=product_name,brands,nutriments,image_url"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Niam iOS App - contact@niam.app", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(APIResponse.self, from: data)

        guard response.status == 1 else { return nil }
        return response.product
    }
}
