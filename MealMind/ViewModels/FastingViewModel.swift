import Foundation
import SwiftData
import Observation

@Observable
final class FastingViewModel {
    var currentSession: FastingSession?
    var history: [FastingSession] = []
    var selectedPlan: FastingPlan = .sixteen8

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        fetchData()
    }

    var isActive: Bool {
        currentSession?.isActive ?? false
    }

    var elapsedFormatted: String {
        guard let session = currentSession else { return "00:00:00" }
        return formatTimeInterval(session.elapsedSeconds)
    }

    var remainingFormatted: String {
        guard let session = currentSession else { return "00:00:00" }
        return formatTimeInterval(session.remainingSeconds)
    }

    var progress: Double {
        currentSession?.progress ?? 0
    }

    func startFasting() {
        let session = FastingSession(startTime: .now, plan: selectedPlan)
        context.insert(session)
        try? context.save()
        currentSession = session
    }

    func stopFasting() {
        currentSession?.endTime = .now
        try? context.save()
        fetchData()
    }

    func fetchData() {
        let descriptor = FetchDescriptor<FastingSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        let all = (try? context.fetch(descriptor)) ?? []
        currentSession = all.first { $0.isActive }
        history = all.filter { !$0.isActive }
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
