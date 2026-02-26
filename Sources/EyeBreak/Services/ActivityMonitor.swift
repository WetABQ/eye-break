import Cocoa

final class ActivityMonitor {
    private(set) var lastActivityTime: Date = Date()
    private var globalMonitor: Any?
    private var localMonitor: Any?

    private let monitoredEvents: NSEvent.EventTypeMask = [
        .mouseMoved, .leftMouseDown, .rightMouseDown,
        .keyDown, .scrollWheel, .leftMouseDragged, .rightMouseDragged
    ]

    func startMonitoring() {
        lastActivityTime = Date()

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: monitoredEvents) { [weak self] _ in
            self?.lastActivityTime = Date()
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: monitoredEvents) { [weak self] event in
            self?.lastActivityTime = Date()
            return event
        }
    }

    func stopMonitoring() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    func idleDuration() -> TimeInterval {
        Date().timeIntervalSince(lastActivityTime)
    }

    deinit {
        stopMonitoring()
    }
}
