import Foundation

struct ParsedRecipe {
    var title: String = ""
    var cuisine: Cuisine = .chinese
    var scenes: Set<MealScene> = [.mainMeal]
    var mainIngredients: [Ingredient] = []
    var sideIngredients: [Ingredient] = []
    var seasonings: [Ingredient] = []
    var steps: [String] = []
    var notes: String = ""
    var servings: Int? = nil
    var prepTimeMinutes: Int = 0
    var cookTimeMinutes: Int = 0
    var caloriesPerServing: Int? = nil
}

enum RecipePasteParser {

    static func parse(_ text: String) -> ParsedRecipe? {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        var result = ParsedRecipe()
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { return nil }

        // Title: first non-empty line, strip leading #/【】
        result.title = extractTitle(lines[0])

        // Cuisine detection from full text
        result.cuisine = detectCuisine(text)

        // Scene detection
        result.scenes = detectScenes(text)

        // Time
        result.prepTimeMinutes = extractTime(text, keywords: ["准备", "prep", "备料", "腌制"])
        result.cookTimeMinutes = extractTime(text, keywords: ["烹饪", "cook", "烹调", "制作时间", "总时间"])
        if result.cookTimeMinutes == 0 {
            result.cookTimeMinutes = extractFirstTime(text)
        }

        // Servings
        result.servings = extractServings(text)

        // Calories
        result.caloriesPerServing = extractCalories(text)

        // Ingredients + steps: parse by section
        let (main, side, season, steps, notes) = extractSections(lines)
        result.mainIngredients = main
        result.sideIngredients = side
        result.seasonings = season
        result.steps = steps
        result.notes = notes

        // Must have at least a title
        guard !result.title.isEmpty else { return nil }
        return result
    }

    // MARK: - Title

    private static func extractTitle(_ line: String) -> String {
        var s = line
        // Strip markdown headers
        s = s.replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
        // Strip 【】《》「」
        s = s.replacingOccurrences(of: "[【】《》「」\\[\\]]", with: "", options: .regularExpression)
        // Strip emoji at start
        s = s.replacingOccurrences(of: "^[\\p{So}\\p{Cn}]+\\s*", with: "", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Cuisine

    private static func detectCuisine(_ text: String) -> Cuisine {
        let t = text.lowercased()
        if t.contains("意大利") || t.contains("pasta") || t.contains("pizza") || t.contains("italian") { return .italian }
        if t.contains("日式") || t.contains("日本") || t.contains("japanese") || t.contains("ラーメン") { return .japanese }
        if t.contains("韩式") || t.contains("韩国") || t.contains("korean") || t.contains("김치") { return .korean }
        if t.contains("泰式") || t.contains("泰国") || t.contains("thai") { return .thai }
        if t.contains("法式") || t.contains("法国") || t.contains("french") { return .french }
        if t.contains("墨西哥") || t.contains("mexican") { return .mexican }
        if t.contains("印度") || t.contains("indian") || t.contains("curry") { return .indian }
        if t.contains("美式") || t.contains("american") || t.contains("burger") { return .american }
        if t.contains("地中海") || t.contains("mediterranean") { return .mediterranean }
        return .chinese
    }

    // MARK: - Scene

    private static func detectScenes(_ text: String) -> Set<MealScene> {
        let t = text.lowercased()
        var scenes = Set<MealScene>()
        if t.contains("早餐") || t.contains("breakfast") { scenes.insert(.breakfast) }
        if t.contains("甜点") || t.contains("dessert") || t.contains("蛋糕") || t.contains("布丁") { scenes.insert(.dessert) }
        if t.contains("饮料") || t.contains("drink") || t.contains("茶") || t.contains("咖啡") || t.contains("果汁") { scenes.insert(.drink) }
        if t.contains("零食") || t.contains("snack") { scenes.insert(.snack) }
        if t.contains("下午茶") || t.contains("afternoon tea") { scenes.insert(.afternoonTea) }
        if t.contains("夜宵") || t.contains("宵夜") { scenes.insert(.lateNight) }
        return scenes.isEmpty ? [.mainMeal] : scenes
    }

    // MARK: - Time

    private static func extractTime(_ text: String, keywords: [String]) -> Int {
        for kw in keywords {
            let pattern = "\(kw)[^\\d]*?(\\d+)\\s*(?:分钟|分|min|minutes?)"
            if let m = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let sub = String(text[m])
                if let n = sub.components(separatedBy: .decimalDigits.inverted)
                    .compactMap({ Int($0) }).first {
                    return n
                }
            }
        }
        return 0
    }

    private static func extractFirstTime(_ text: String) -> Int {
        let pattern = "(\\d+)\\s*(?:分钟|分|min|minutes?)"
        if let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
            let sub = String(text[range])
            if let n = sub.components(separatedBy: .decimalDigits.inverted)
                .compactMap({ Int($0) }).first {
                return n
            }
        }
        return 0
    }

    // MARK: - Servings

    private static func extractServings(_ text: String) -> Int? {
        let patterns = [
            "(\\d+)\\s*(?:人份|人|servings?|portions?)",
            "(?:份量|serves?|servings?)\\s*[：:]?\\s*(\\d+)",
        ]
        for pattern in patterns {
            if let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let sub = String(text[range])
                if let n = sub.components(separatedBy: .decimalDigits.inverted)
                    .compactMap({ Int($0) }).first {
                    return n
                }
            }
        }
        return nil
    }

    // MARK: - Calories

    private static func extractCalories(_ text: String) -> Int? {
        let pattern = "(\\d+)\\s*(?:kcal|卡路里|千卡|卡)"
        if let range = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
            let sub = String(text[range])
            if let n = sub.components(separatedBy: .decimalDigits.inverted)
                .compactMap({ Int($0) }).first {
                return n
            }
        }
        return nil
    }

    // MARK: - Sections

    private static func extractSections(_ lines: [String]) -> (
        main: [Ingredient], side: [Ingredient], season: [Ingredient],
        steps: [String], notes: String
    ) {
        var main: [Ingredient] = []
        var side: [Ingredient] = []
        var season: [Ingredient] = []
        var steps: [String] = []
        var notes = ""

        enum Section { case none, ingredient, step, notes }
        var current: Section = .none
        var ingredientTarget: WritableKeyPath<[Ingredient], [Ingredient]>? = nil

        // Markers
        let ingredientHeaders = ["食材", "材料", "用料", "ingredients", "配料"]
        let mainHeaders = ["主料", "主食材", "main"]
        let sideHeaders = ["配料", "配菜", "辅料", "side"]
        let seasonHeaders = ["调料", "调味料", "seasoning", "sauce"]
        let stepHeaders = ["步骤", "做法", "方法", "instructions", "directions", "制作"]
        let notesHeaders = ["备注", "小贴士", "tips", "notes", "注意"]

        func isHeader(_ line: String, _ keywords: [String]) -> Bool {
            let l = line.lowercased()
            return keywords.contains { l.contains($0) } &&
                   (line.hasPrefix("#") || line.hasSuffix("：") || line.hasSuffix(":") ||
                    line.hasPrefix("【") || line.count < 12)
        }

        for (i, line) in lines.enumerated() {
            if i == 0 { continue } // skip title

            let low = line.lowercased()

            if isHeader(line, stepHeaders) { current = .step; continue }
            if isHeader(line, notesHeaders) { current = .notes; continue }
            if isHeader(line, mainHeaders) { current = .ingredient; ingredientTarget = \.self; continue }
            if isHeader(line, sideHeaders) && current == .ingredient { continue }
            if isHeader(line, seasonHeaders) { current = .ingredient; continue }
            if isHeader(line, ingredientHeaders) { current = .ingredient; continue }

            switch current {
            case .step:
                // Numbered step or bullet
                var stepText = line
                stepText = stepText.replacingOccurrences(of: "^\\d+[.、。）)\\s]+", with: "", options: .regularExpression)
                stepText = stepText.replacingOccurrences(of: "^[-•·]\\s*", with: "", options: .regularExpression)
                if !stepText.isEmpty && stepText.count > 2 {
                    steps.append(stepText)
                }

            case .ingredient:
                if let ing = parseIngredientLine(line) {
                    // Heuristic: if it contains salt/sugar/soy/oil → seasoning
                    let n = ing.name
                    if isSeasoningName(n) {
                        season.append(ing)
                    } else if isGarnishName(n) {
                        side.append(ing)
                    } else {
                        main.append(ing)
                    }
                }

            case .notes:
                notes += (notes.isEmpty ? "" : "\n") + line

            case .none:
                // Try to auto-detect numbered steps
                if line.range(of: "^\\d+[.、。）)]\\s+\\S", options: .regularExpression) != nil {
                    current = .step
                    var stepText = line.replacingOccurrences(of: "^\\d+[.、。）)\\s]+", with: "", options: .regularExpression)
                    if !stepText.isEmpty { steps.append(stepText) }
                } else if let ing = parseIngredientLine(line), current == .none {
                    // Looks like an ingredient even without header
                    if isSeasoningName(ing.name) { season.append(ing) }
                    else { main.append(ing) }
                }
            }
        }

        return (main, side, season, steps, notes)
    }

    // MARK: - Ingredient line parser

    private static func parseIngredientLine(_ line: String) -> Ingredient? {
        var s = line
        // Strip bullets
        s = s.replacingOccurrences(of: "^[-•·*]\\s*", with: "", options: .regularExpression)
        s = s.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty, s.count > 1 else { return nil }

        // Skip lines that look like headers or steps
        if s.hasPrefix("#") || s.range(of: "^\\d+[.。、）]", options: .regularExpression) != nil { return nil }

        let units = "g|克|kg|千克|ml|毫升|L|升|个|只|颗|瓣|片|根|条|块|勺|大勺|小勺|汤匙|茶匙|杯|把|束|朵|滴|罐|包|袋|份|张|粒|茎|段|头|棵|碗"
        let pattern = "^(.+?)\\s+(\\d+\\.?\\d*)\\s*(\(units))(.*)$"

        if let range = s.range(of: pattern, options: .regularExpression) {
            let sub = String(s[range])
            // Extract via capture
            let re = try? NSRegularExpression(pattern: "^(.+?)\\s+(\\d+\\.?\\d*)\\s*(\(units))", options: [])
            if let m = re?.firstMatch(in: sub, range: NSRange(sub.startIndex..., in: sub)) {
                let name = (sub as NSString).substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespaces)
                let qty = Double((sub as NSString).substring(with: m.range(at: 2))) ?? 1.0
                let unit = (sub as NSString).substring(with: m.range(at: 3))
                let foodUnit = FoodUnit(rawValue: unit) ?? .gram
                return Ingredient(name: name, quantity: qty, unit: foodUnit)
            }
        }

        // "适量/少许" pattern: name + 适量
        let approxPattern = "^(.+?)\\s*(适量|少量|少许|适当|若干)$"
        if let range = s.range(of: approxPattern, options: .regularExpression) {
            let sub = String(s[range])
            let re = try? NSRegularExpression(pattern: "^(.+?)\\s*(适量|少量|少许|适当|若干)$", options: [])
            if let m = re?.firstMatch(in: sub, range: NSRange(sub.startIndex..., in: sub)) {
                let name = (sub as NSString).substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespaces)
                return Ingredient(name: name, quantity: 1.0, unit: .gram)
            }
        }

        // Plain name only (no quantity) — still include as ingredient if in ingredient section
        if s.count <= 20, !s.contains("："), !s.contains(":"), !s.contains("。") {
            return Ingredient(name: s, quantity: 1.0, unit: .gram)
        }

        return nil
    }

    // MARK: - Name heuristics

    private static let seasoningKeywords = [
        "盐", "糖", "酱油", "醋", "料酒", "老抽", "生抽", "蚝油", "豆瓣酱", "辣椒酱",
        "花椒", "八角", "桂皮", "香叶", "胡椒", "孜然", "五香", "淀粉", "面粉",
        "油", "黄油", "橄榄油", "香油", "芝麻油", "味精", "鸡精", "白糖", "红糖",
        "蜂蜜", "番茄酱", "芥末", "咖喱", "酱", "粉", "sauce", "salt", "sugar",
        "pepper", "oil", "vinegar", "soy", "flour", "starch",
    ]

    private static let garnishKeywords = [
        "葱", "姜", "蒜", "辣椒", "香菜", "欧芹", "罗勒", "薄荷", "迷迭香",
        "百里香", "柠檬", "青葱", "韭菜", "芹菜", "parsley", "basil", "garlic",
        "ginger", "chili", "scallion",
    ]

    private static func isSeasoningName(_ name: String) -> Bool {
        let n = name.lowercased()
        return seasoningKeywords.contains { n.contains($0) }
    }

    private static func isGarnishName(_ name: String) -> Bool {
        let n = name.lowercased()
        return garnishKeywords.contains { n.contains($0) }
    }
}
