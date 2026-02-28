import Cocoa

final class WorkTimerService {
    private let appState: AppState
    private let settings: AppSettings
    private let activityMonitor: ActivityMonitor
    private let breakManager: BreakManager
    private let mediaMonitor: MediaPlaybackMonitor

    private var tickTimer: Timer?
    private var sleepObserver: Any?
    private var wakeObserver: Any?

    init(appState: AppState, settings: AppSettings, activityMonitor: ActivityMonitor, breakManager: BreakManager, mediaMonitor: MediaPlaybackMonitor) {
        self.appState = appState
        self.settings = settings
        self.activityMonitor = activityMonitor
        self.breakManager = breakManager
        self.mediaMonitor = mediaMonitor

        self.breakManager.onBreakFinished = { [weak self] in
            self?.transitionToIdle()
        }

        observeSleepWake()
    }

    func start() {
        activityMonitor.startMonitoring()
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: Constants.timerTickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        tickTimer?.invalidate()
        tickTimer = nil
        activityMonitor.stopMonitoring()
        transitionToIdle()
    }

    private func tick() {
        guard settings.isEnabled else { return }
        guard !breakManager.isOnBreak() else { return }

        let idle = activityMonitor.idleDuration()

        let mediaPlaying = settings.countMediaAsScreenTime && mediaMonitor.isMediaPlaying()

        switch appState.phase {
        case .idle:
            if mediaPlaying {
                // Media is playing — start fresh work timer
                appState.phase = .working
                appState.elapsedWork = 1
            } else if idle < settings.idleThreshold {
                // User became active
                appState.phase = .working
                appState.elapsedWork = idle < 2 ? 1 : idle
            }

        case .working:
            if idle >= settings.idleThreshold && !mediaPlaying {
                // User went idle long enough and no media playing — reset
                transitionToIdle()
            } else {
                appState.elapsedWork += 1
                if appState.elapsedWork >= settings.workDuration {
                    breakManager.startBreak()
                }
            }

        case .onBreak:
            break
        }
    }

    private func transitionToIdle() {
        appState.phase = .idle
        appState.elapsedWork = 0
    }

    private func observeSleepWake() {
        let ws = NSWorkspace.shared.notificationCenter

        sleepObserver = ws.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.tickTimer?.invalidate()
            self?.tickTimer = nil
            self?.activityMonitor.stopMonitoring()
        }

        wakeObserver = ws.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.transitionToIdle()
            self?.start()
        }
    }

    deinit {
        tickTimer?.invalidate()
        if let sleepObserver { NSWorkspace.shared.notificationCenter.removeObserver(sleepObserver) }
        if let wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver) }
    }
}
