import Foundation
import SwiftData

@Model
final class FastingSession {
    var startTime: Date
    var endTime: Date?
    var targetHours: Int

    init(startTime: Date = .now, targetHours: Int = 16) {
        self.startTime = startTime
        self.targetHours = targetHours
    }

    var targetEndTime: Date {
        Calendar.current.date(byAdding: .hour, value: targetHours, to: startTime)!
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
        let total = TimeInterval(targetHours * 3600)
        return min(1.0, elapsedSeconds / total)
    }
}
