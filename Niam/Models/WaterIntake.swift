import Foundation
import SwiftData

@Model
final class WaterIntake {
    var date: Date
    var count: Int
    var target: Int

    init(date: Date = .now, count: Int = 0, target: Int = 8) {
        self.date = Calendar.current.startOfDay(for: date)
        self.count = count
        self.target = target
    }
}
