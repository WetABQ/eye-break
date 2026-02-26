import Foundation

enum AppPhase: String {
    case idle
    case working
    case onBreak
}

@Observable
final class AppState {
    var phase: AppPhase = .idle
    var elapsedWork: TimeInterval = 0
    var remainingBreak: TimeInterval = 0
    var hasAccessibilityPermission: Bool = false

    var workProgress: Double {
        guard let settings = settings else { return 0 }
        return min(elapsedWork / settings.workDuration, 1.0)
    }

    var formattedElapsed: String {
        formatTime(elapsedWork)
    }

    var formattedRemaining: String {
        formatTime(remainingBreak)
    }

    var formattedWorkLeft: String {
        guard let settings = settings else { return "--:--" }
        let left = max(settings.workDuration - elapsedWork, 0)
        return formatTime(left)
    }

    weak var settings: AppSettings?

    private func formatTime(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
