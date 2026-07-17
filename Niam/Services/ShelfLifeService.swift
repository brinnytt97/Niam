import Foundation

/// Built-in shelf life dictionary for common ingredients (days in fridge).
/// Fuzzy matches ingredient names and returns estimated shelf life.
enum ShelfLifeService {

    struct ShelfLifeEntry {
        let name: String
        let days: Int
        let category: FoodCategory
    }

    /// Search for matching ingredients. Returns best matches sorted by relevance.
    static func lookup(_ query: String) -> [ShelfLifeEntry] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }

        return entries.filter { entry in
            entry.name.lowercased().contains(q) || q.contains(entry.name.lowercased())
        }
    }

    /// Get the best match shelf life in days, or nil if no match.
    static func estimatedDays(for name: String) -> Int? {
        let q = name.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return nil }

        // Exact match first
        if let exact = entries.first(where: { $0.name.lowercased() == q }) {
            return exact.days
        }
        // Contains match
        if let partial = entries.first(where: {
            $0.name.lowercased().contains(q) || q.contains($0.name.lowercased())
        }) {
            return partial.days
        }
        return nil
    }

    /// Get suggested category for an ingredient name.
    static func suggestedCategory(for name: String) -> FoodCategory? {
        let q = name.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return nil }

        if let exact = entries.first(where: { $0.name.lowercased() == q }) {
            return exact.category
        }
        if let partial = entries.first(where: {
            $0.name.lowercased().contains(q) || q.contains($0.name.lowercased())
        }) {
            return partial.category
        }
        return nil
    }

    // MARK: - Dictionary (~150 common ingredients)

    static let entries: [ShelfLifeEntry] = [
        // === Dairy ===
        ShelfLifeEntry(name: "Milk", days: 7, category: .dairy),
        ShelfLifeEntry(name: "Yogurt", days: 14, category: .dairy),
        ShelfLifeEntry(name: "Cheese", days: 21, category: .dairy),
        ShelfLifeEntry(name: "Cream cheese", days: 14, category: .dairy),
        ShelfLifeEntry(name: "Butter", days: 30, category: .dairy),
        ShelfLifeEntry(name: "Heavy cream", days: 10, category: .dairy),
        ShelfLifeEntry(name: "Sour cream", days: 14, category: .dairy),
        ShelfLifeEntry(name: "Mozzarella", days: 7, category: .dairy),
        ShelfLifeEntry(name: "Parmesan", days: 42, category: .dairy),
        ShelfLifeEntry(name: "Eggs", days: 30, category: .dairy),
        // 牛奶/酸奶 Chinese names
        ShelfLifeEntry(name: "牛奶", days: 7, category: .dairy),
        ShelfLifeEntry(name: "酸奶", days: 14, category: .dairy),
        ShelfLifeEntry(name: "奶酪", days: 21, category: .dairy),
        ShelfLifeEntry(name: "黄油", days: 30, category: .dairy),
        ShelfLifeEntry(name: "鸡蛋", days: 30, category: .dairy),
        ShelfLifeEntry(name: "淡奶油", days: 10, category: .dairy),

        // === Meat ===
        ShelfLifeEntry(name: "Chicken breast", days: 2, category: .meat),
        ShelfLifeEntry(name: "Chicken thigh", days: 2, category: .meat),
        ShelfLifeEntry(name: "Chicken", days: 2, category: .meat),
        ShelfLifeEntry(name: "Ground beef", days: 2, category: .meat),
        ShelfLifeEntry(name: "Beef steak", days: 4, category: .meat),
        ShelfLifeEntry(name: "Beef", days: 4, category: .meat),
        ShelfLifeEntry(name: "Pork", days: 3, category: .meat),
        ShelfLifeEntry(name: "Pork chop", days: 3, category: .meat),
        ShelfLifeEntry(name: "Bacon", days: 7, category: .meat),
        ShelfLifeEntry(name: "Ham", days: 5, category: .meat),
        ShelfLifeEntry(name: "Sausage", days: 5, category: .meat),
        ShelfLifeEntry(name: "Lamb", days: 3, category: .meat),
        ShelfLifeEntry(name: "Turkey", days: 2, category: .meat),
        ShelfLifeEntry(name: "Duck", days: 2, category: .meat),
        // Chinese
        ShelfLifeEntry(name: "鸡胸肉", days: 2, category: .meat),
        ShelfLifeEntry(name: "鸡腿", days: 2, category: .meat),
        ShelfLifeEntry(name: "鸡肉", days: 2, category: .meat),
        ShelfLifeEntry(name: "猪肉", days: 3, category: .meat),
        ShelfLifeEntry(name: "牛肉", days: 4, category: .meat),
        ShelfLifeEntry(name: "牛排", days: 4, category: .meat),
        ShelfLifeEntry(name: "羊肉", days: 3, category: .meat),
        ShelfLifeEntry(name: "培根", days: 7, category: .meat),
        ShelfLifeEntry(name: "火腿", days: 5, category: .meat),
        ShelfLifeEntry(name: "香肠", days: 5, category: .meat),
        ShelfLifeEntry(name: "鸭肉", days: 2, category: .meat),
        ShelfLifeEntry(name: "肉末", days: 2, category: .meat),
        ShelfLifeEntry(name: "五花肉", days: 3, category: .meat),
        ShelfLifeEntry(name: "排骨", days: 3, category: .meat),

        // === Seafood ===
        ShelfLifeEntry(name: "Salmon", days: 2, category: .seafood),
        ShelfLifeEntry(name: "Shrimp", days: 2, category: .seafood),
        ShelfLifeEntry(name: "Tuna", days: 2, category: .seafood),
        ShelfLifeEntry(name: "Cod", days: 2, category: .seafood),
        ShelfLifeEntry(name: "Crab", days: 2, category: .seafood),
        ShelfLifeEntry(name: "Squid", days: 2, category: .seafood),
        ShelfLifeEntry(name: "Clam", days: 2, category: .seafood),
        ShelfLifeEntry(name: "Mussel", days: 2, category: .seafood),
        // Chinese
        ShelfLifeEntry(name: "三文鱼", days: 2, category: .seafood),
        ShelfLifeEntry(name: "虾", days: 2, category: .seafood),
        ShelfLifeEntry(name: "鱼", days: 2, category: .seafood),
        ShelfLifeEntry(name: "螃蟹", days: 2, category: .seafood),
        ShelfLifeEntry(name: "鱿鱼", days: 2, category: .seafood),
        ShelfLifeEntry(name: "带鱼", days: 2, category: .seafood),

        // === Vegetables ===
        ShelfLifeEntry(name: "Lettuce", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "Spinach", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "Broccoli", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "Carrot", days: 21, category: .vegetable),
        ShelfLifeEntry(name: "Tomato", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "Cucumber", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "Bell pepper", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "Onion", days: 30, category: .vegetable),
        ShelfLifeEntry(name: "Garlic", days: 30, category: .vegetable),
        ShelfLifeEntry(name: "Ginger", days: 21, category: .vegetable),
        ShelfLifeEntry(name: "Potato", days: 21, category: .vegetable),
        ShelfLifeEntry(name: "Sweet potato", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "Cabbage", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "Celery", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "Mushroom", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "Corn", days: 3, category: .vegetable),
        ShelfLifeEntry(name: "Zucchini", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "Eggplant", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "Green bean", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "Asparagus", days: 4, category: .vegetable),
        ShelfLifeEntry(name: "Kale", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "Cauliflower", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "Bok choy", days: 4, category: .vegetable),
        ShelfLifeEntry(name: "Snow pea", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "Sugar snap pea", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "Radish", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "Turnip", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "Beet", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "Leek", days: 10, category: .vegetable),
        ShelfLifeEntry(name: "Spring onion", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "Green onion", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "Scallion", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "Chili pepper", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "Jalapeno", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "Pumpkin", days: 30, category: .vegetable),
        ShelfLifeEntry(name: "Butternut squash", days: 30, category: .vegetable),
        ShelfLifeEntry(name: "Artichoke", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "Brussels sprout", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "Arugula", days: 4, category: .vegetable),
        ShelfLifeEntry(name: "Watercress", days: 3, category: .vegetable),
        ShelfLifeEntry(name: "Swiss chard", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "Fennel", days: 10, category: .vegetable),
        ShelfLifeEntry(name: "Okra", days: 3, category: .vegetable),
        ShelfLifeEntry(name: "Daikon", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "Bamboo shoot", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "Bean sprout", days: 3, category: .vegetable),
        ShelfLifeEntry(name: "Water chestnut", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "Taro", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "Yam", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "Edamame", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "Pea", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "Cherry tomato", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "Roma tomato", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "Baby spinach", days: 4, category: .vegetable),
        ShelfLifeEntry(name: "Mixed greens", days: 4, category: .vegetable),
        ShelfLifeEntry(name: "Romaine lettuce", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "Iceberg lettuce", days: 10, category: .vegetable),
        ShelfLifeEntry(name: "Red cabbage", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "Napa cabbage", days: 10, category: .vegetable),
        ShelfLifeEntry(name: "Shallot", days: 30, category: .vegetable),
        ShelfLifeEntry(name: "Parsley", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "Cilantro", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "Basil", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "Mint", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "Dill", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "Rosemary", days: 10, category: .vegetable),
        ShelfLifeEntry(name: "Thyme", days: 7, category: .vegetable),
        // Chinese
        ShelfLifeEntry(name: "生菜", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "菠菜", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "西兰花", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "胡萝卜", days: 21, category: .vegetable),
        ShelfLifeEntry(name: "番茄", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "西红柿", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "黄瓜", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "洋葱", days: 30, category: .vegetable),
        ShelfLifeEntry(name: "大蒜", days: 30, category: .vegetable),
        ShelfLifeEntry(name: "姜", days: 21, category: .vegetable),
        ShelfLifeEntry(name: "土豆", days: 21, category: .vegetable),
        ShelfLifeEntry(name: "红薯", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "白菜", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "大白菜", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "芹菜", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "蘑菇", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "香菇", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "玉米", days: 3, category: .vegetable),
        ShelfLifeEntry(name: "茄子", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "豆角", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "青椒", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "豆腐", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "豆芽", days: 3, category: .vegetable),
        ShelfLifeEntry(name: "藕", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "南瓜", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "韭菜", days: 3, category: .vegetable),
        ShelfLifeEntry(name: "葱", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "小葱", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "香葱", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "蒜苗", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "蒜苔", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "油菜", days: 4, category: .vegetable),
        ShelfLifeEntry(name: "小白菜", days: 4, category: .vegetable),
        ShelfLifeEntry(name: "上海青", days: 4, category: .vegetable),
        ShelfLifeEntry(name: "空心菜", days: 3, category: .vegetable),
        ShelfLifeEntry(name: "通菜", days: 3, category: .vegetable),
        ShelfLifeEntry(name: "娃娃菜", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "花菜", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "菜花", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "莴笋", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "油麦菜", days: 4, category: .vegetable),
        ShelfLifeEntry(name: "苋菜", days: 3, category: .vegetable),
        ShelfLifeEntry(name: "荠菜", days: 3, category: .vegetable),
        ShelfLifeEntry(name: "香菜", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "木耳", days: 180, category: .vegetable),
        ShelfLifeEntry(name: "银耳", days: 180, category: .vegetable),
        ShelfLifeEntry(name: "金针菇", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "杏鲍菇", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "平菇", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "秀珍菇", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "丝瓜", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "苦瓜", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "冬瓜", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "西葫芦", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "萝卜", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "白萝卜", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "红萝卜", days: 21, category: .vegetable),
        ShelfLifeEntry(name: "山药", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "芋头", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "荸荠", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "竹笋", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "笋", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "毛豆", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "豌豆", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "荷兰豆", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "四季豆", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "秋葵", days: 3, category: .vegetable),
        ShelfLifeEntry(name: "红椒", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "彩椒", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "尖椒", days: 7, category: .vegetable),
        ShelfLifeEntry(name: "小米椒", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "辣椒", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "紫甘蓝", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "圆白菜", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "卷心菜", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "甘蓝", days: 14, category: .vegetable),
        ShelfLifeEntry(name: "芥蓝", days: 5, category: .vegetable),
        ShelfLifeEntry(name: "菜心", days: 4, category: .vegetable),
        ShelfLifeEntry(name: "茼蒿", days: 3, category: .vegetable),
        ShelfLifeEntry(name: "蕨菜", days: 3, category: .vegetable),
        ShelfLifeEntry(name: "黄花菜", days: 180, category: .vegetable),
        ShelfLifeEntry(name: "腐竹", days: 180, category: .vegetable),
        ShelfLifeEntry(name: "粉丝", days: 365, category: .vegetable),
        ShelfLifeEntry(name: "粉条", days: 365, category: .vegetable),

        // === Fruit ===
        ShelfLifeEntry(name: "Apple", days: 21, category: .fruit),
        ShelfLifeEntry(name: "Banana", days: 5, category: .fruit),
        ShelfLifeEntry(name: "Orange", days: 14, category: .fruit),
        ShelfLifeEntry(name: "Strawberry", days: 5, category: .fruit),
        ShelfLifeEntry(name: "Blueberry", days: 7, category: .fruit),
        ShelfLifeEntry(name: "Grape", days: 7, category: .fruit),
        ShelfLifeEntry(name: "Lemon", days: 21, category: .fruit),
        ShelfLifeEntry(name: "Lime", days: 14, category: .fruit),
        ShelfLifeEntry(name: "Avocado", days: 4, category: .fruit),
        ShelfLifeEntry(name: "Mango", days: 5, category: .fruit),
        ShelfLifeEntry(name: "Peach", days: 5, category: .fruit),
        ShelfLifeEntry(name: "Pear", days: 7, category: .fruit),
        ShelfLifeEntry(name: "Watermelon", days: 5, category: .fruit),
        ShelfLifeEntry(name: "Pineapple", days: 5, category: .fruit),
        ShelfLifeEntry(name: "Kiwi", days: 7, category: .fruit),
        // Chinese
        ShelfLifeEntry(name: "苹果", days: 21, category: .fruit),
        ShelfLifeEntry(name: "香蕉", days: 5, category: .fruit),
        ShelfLifeEntry(name: "橘子", days: 14, category: .fruit),
        ShelfLifeEntry(name: "橙子", days: 14, category: .fruit),
        ShelfLifeEntry(name: "草莓", days: 5, category: .fruit),
        ShelfLifeEntry(name: "蓝莓", days: 7, category: .fruit),
        ShelfLifeEntry(name: "葡萄", days: 7, category: .fruit),
        ShelfLifeEntry(name: "柠檬", days: 21, category: .fruit),
        ShelfLifeEntry(name: "牛油果", days: 4, category: .fruit),
        ShelfLifeEntry(name: "芒果", days: 5, category: .fruit),
        ShelfLifeEntry(name: "桃子", days: 5, category: .fruit),
        ShelfLifeEntry(name: "梨", days: 7, category: .fruit),
        ShelfLifeEntry(name: "西瓜", days: 5, category: .fruit),

        // === Grain / Bread ===
        ShelfLifeEntry(name: "Bread", days: 5, category: .grain),
        ShelfLifeEntry(name: "Tortilla", days: 7, category: .grain),
        ShelfLifeEntry(name: "Rice", days: 180, category: .grain),
        ShelfLifeEntry(name: "Pasta", days: 180, category: .grain),
        ShelfLifeEntry(name: "Noodles", days: 3, category: .grain),
        ShelfLifeEntry(name: "Oats", days: 180, category: .grain),
        ShelfLifeEntry(name: "Cereal", days: 180, category: .grain),
        // Chinese
        ShelfLifeEntry(name: "面包", days: 5, category: .grain),
        ShelfLifeEntry(name: "米饭", days: 2, category: .grain),
        ShelfLifeEntry(name: "大米", days: 180, category: .grain),
        ShelfLifeEntry(name: "面条", days: 3, category: .grain),
        ShelfLifeEntry(name: "挂面", days: 180, category: .grain),
        ShelfLifeEntry(name: "燕麦", days: 180, category: .grain),
        ShelfLifeEntry(name: "麦片", days: 180, category: .grain),
        ShelfLifeEntry(name: "馒头", days: 3, category: .grain),
        ShelfLifeEntry(name: "包子", days: 2, category: .grain),
        ShelfLifeEntry(name: "饺子", days: 2, category: .grain),

        // === Condiment ===
        ShelfLifeEntry(name: "Soy sauce", days: 365, category: .condiment),
        ShelfLifeEntry(name: "Ketchup", days: 180, category: .condiment),
        ShelfLifeEntry(name: "Mayonnaise", days: 60, category: .condiment),
        ShelfLifeEntry(name: "Mustard", days: 365, category: .condiment),
        ShelfLifeEntry(name: "Olive oil", days: 365, category: .condiment),
        ShelfLifeEntry(name: "Vinegar", days: 365, category: .condiment),
        ShelfLifeEntry(name: "Salt", days: 3650, category: .condiment),
        ShelfLifeEntry(name: "Sugar", days: 3650, category: .condiment),
        // Chinese
        ShelfLifeEntry(name: "酱油", days: 365, category: .condiment),
        ShelfLifeEntry(name: "醋", days: 365, category: .condiment),
        ShelfLifeEntry(name: "盐", days: 3650, category: .condiment),
        ShelfLifeEntry(name: "糖", days: 3650, category: .condiment),
        ShelfLifeEntry(name: "料酒", days: 365, category: .condiment),
        ShelfLifeEntry(name: "蚝油", days: 180, category: .condiment),
        ShelfLifeEntry(name: "豆瓣酱", days: 365, category: .condiment),
        ShelfLifeEntry(name: "老抽", days: 365, category: .condiment),
        ShelfLifeEntry(name: "生抽", days: 365, category: .condiment),
        ShelfLifeEntry(name: "花椒", days: 365, category: .condiment),
        ShelfLifeEntry(name: "辣椒", days: 14, category: .condiment),

        // === Beverage ===
        ShelfLifeEntry(name: "Orange juice", days: 7, category: .beverage),
        ShelfLifeEntry(name: "Apple juice", days: 7, category: .beverage),
        ShelfLifeEntry(name: "Beer", days: 180, category: .beverage),
        ShelfLifeEntry(name: "Wine", days: 5, category: .beverage),
        // Chinese
        ShelfLifeEntry(name: "果汁", days: 7, category: .beverage),
        ShelfLifeEntry(name: "豆浆", days: 2, category: .beverage),
    ]
}
