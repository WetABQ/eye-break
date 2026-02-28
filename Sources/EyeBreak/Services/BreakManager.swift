import Foundation

final class BreakManager {
    private let appState: AppState
    private let settings: AppSettings
    private let overlayManager: OverlayWindowManager
    private var breakTimer: Timer?
    private var isPreview = false
    private var savedPhase: AppPhase?
    private var savedElapsedWork: TimeInterval?

    var onBreakFinished: (() -> Void)?

    init(appState: AppState, settings: AppSettings, overlayManager: OverlayWindowManager) {
        self.appState = appState
        self.settings = settings
        self.overlayManager = overlayManager

        self.overlayManager.onSkip = { [weak self] in
            self?.endBreak()
        }
    }

    func startBreak(preview: Bool = false) {
        isPreview = preview
        if preview {
            savedPhase = appState.phase
            savedElapsedWork = appState.elapsedWork
        }
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
            if isPreview, let phase = savedPhase, let elapsed = savedElapsedWork {
                appState.phase = phase
                appState.elapsedWork = elapsed
                savedPhase = nil
                savedElapsedWork = nil
            } else {
                onBreakFinished?()
            }
            isPreview = false
        }
    }

    func isOnBreak() -> Bool {
        appState.phase == .onBreak
    }
}
