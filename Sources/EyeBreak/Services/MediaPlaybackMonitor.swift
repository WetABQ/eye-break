import Foundation
import IOKit.pwr_mgt

final class MediaPlaybackMonitor {
    private var cachedResult = false
    private var lastCheckTime: TimeInterval = 0
    private var lastMediaDetectedTime: TimeInterval = 0
    private let cacheInterval: TimeInterval = 3
    /// Keep reporting "playing" for this long after the last real detection,
    /// bridging brief gaps (ad transitions, buffering, between episodes).
    private let graceInterval: TimeInterval = 15

    /// Processes that hold display-sleep assertions but aren't media playback.
    private let ignoredProcesses: Set<String> = [
        "caffeinate",
        "powerd",
        "Keynote",
        "PowerPoint",
        "Google Slides",
    ]

    /// Assertion types that indicate display-active media playback.
    /// Modern apps use PreventUserIdleDisplaySleep; legacy apps / some
    /// browsers (e.g. Arc) use NoDisplaySleepAssertion.
    private let mediaAssertionTypes: Set<String> = [
        "PreventUserIdleDisplaySleep",  // kIOPMAssertionTypePreventUserIdleDisplaySleep
        "NoDisplaySleepAssertion",      // kIOPMAssertionTypeNoDisplaySleep (legacy)
    ]

    func isMediaPlaying() -> Bool {
        let now = ProcessInfo.processInfo.systemUptime
        if now - lastCheckTime < cacheInterval {
            return cachedResult
        }
        lastCheckTime = now

        let detected = queryAssertions()
        if detected {
            lastMediaDetectedTime = now
        }
        // Real detection OR still within grace period after last detection.
        cachedResult = detected || (now - lastMediaDetectedTime < graceInterval)
        return cachedResult
    }

    private func queryAssertions() -> Bool {
        var assertionsByProcess: Unmanaged<CFDictionary>?
        let result = IOPMCopyAssertionsByProcess(&assertionsByProcess)
        guard result == kIOReturnSuccess,
              let dict = assertionsByProcess?.takeRetainedValue() as? [String: [[String: Any]]] else {
            return false
        }

        for (processName, assertions) in dict {
            if ignoredProcesses.contains(processName) { continue }

            for assertion in assertions {
                if let type = assertion[kIOPMAssertionTypeKey] as? String,
                   mediaAssertionTypes.contains(type) {
                    return true
                }
            }
        }

        return false
    }
}
