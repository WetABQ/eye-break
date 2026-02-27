import Cocoa

final class ActivityMonitor {
    /// Uses CGEventSource to query system-wide idle time directly from the HID system.
    /// Unlike NSEvent global monitors, this works without Accessibility permission.
    func idleDuration() -> TimeInterval {
        let types: [CGEventType] = [
            .mouseMoved, .leftMouseDown, .rightMouseDown,
            .keyDown, .scrollWheel, .leftMouseDragged, .rightMouseDragged
        ]
        return types.map {
            CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0)
        }.min() ?? 0
    }

    // Kept for API compatibility with WorkTimerService sleep/wake handling.
    func startMonitoring() {}
    func stopMonitoring() {}
}
