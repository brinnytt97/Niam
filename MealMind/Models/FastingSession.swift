import Foundation
import SwiftData

@Model
final class FastingSession {
    var startTime: Date
    var endTime: Date?
    var plan: FastingPlan

    init(startTime: Date = .now, plan: FastingPlan = .sixteen8) {
        self.startTime = startTime
        self.plan = plan
    }

    var targetEndTime: Date {
        Calendar.current.date(byAdding: .hour, value: plan.fastingHours, to: startTime)!
    }

    var isActive: Bool {
        endTime == nil
    }

    var elapsedSeconds: TimeInterval {
        let end = endTime ?? .now
        return end.timeIntervalSince(startTime)
    }

    var remainingSeconds: TimeInterval {
        max(0, targetEndTime.timeIntervalSince(.now))
    }

    var progress: Double {
        let total = TimeInterval(plan.fastingHours * 3600)
        return min(1.0, elapsedSeconds / total)
    }
}

enum FastingPlan: String, Codable, CaseIterable {
    case sixteen8 = "16:8"
    case eighteen6 = "18:6"
    case twenty4 = "20:4"
    case omad = "OMAD (23:1)"

    var fastingHours: Int {
        switch self {
        case .sixteen8: 16
        case .eighteen6: 18
        case .twenty4: 20
        case .omad: 23
        }
    }

    var eatingHours: Int {
        24 - fastingHours
    }
}
