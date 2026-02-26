import Foundation

final class BreakManager {
    private let appState: AppState
    private let settings: AppSettings
    private let overlayManager: OverlayWindowManager
    private var breakTimer: Timer?

    var onBreakFinished: (() -> Void)?

    init(appState: AppState, settings: AppSettings, overlayManager: OverlayWindowManager) {
        self.appState = appState
        self.settings = settings
        self.overlayManager = overlayManager

        self.overlayManager.onSkip = { [weak self] in
            self?.endBreak()
        }
    }

    func startBreak() {
        appState.phase = .onBreak
        appState.remainingBreak = settings.breakDuration

        overlayManager.showOverlay(appState: appState)

        breakTimer?.invalidate()
        breakTimer = Timer.scheduledTimer(withTimeInterval: Constants.timerTickInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.appState.remainingBreak -= 1
            if self.appState.remainingBreak <= 0 {
                self.endBreak()
            }
        }
    }

    func endBreak() {
        breakTimer?.invalidate()
        breakTimer = nil
        // Defer window teardown to next run loop iteration so the
        // Skip button's action closure finishes before its host window is destroyed.
        DispatchQueue.main.async { [self] in
            overlayManager.hideOverlay()
            appState.remainingBreak = 0
            onBreakFinished?()
        }
    }

    func isOnBreak() -> Bool {
        appState.phase == .onBreak
    }
}
