import Foundation
import IOKit.pwr_mgt

final class MediaPlaybackMonitor {
    private var cachedResult = false
    private var lastCheckTime: TimeInterval = 0
    private let cacheInterval: TimeInterval = 5

    /// Processes that hold PreventUserIdleDisplaySleep but aren't media playback.
    private let ignoredProcesses: Set<String> = [
        "caffeinate",
        "powerd",
        "Keynote",
        "PowerPoint",
        "Google Slides",
    ]

    /// Returns `true` if a media-like process holds a `PreventUserIdleDisplaySleep`
    /// assertion, indicating active video playback.
    /// Result is cached for 5 seconds to reduce overhead.
    func isMediaPlaying() -> Bool {
        let now = ProcessInfo.processInfo.systemUptime
        if now - lastCheckTime < cacheInterval {
            return cachedResult
        }
        lastCheckTime = now
        cachedResult = queryAssertions()
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
                   type == kIOPMAssertionTypePreventUserIdleDisplaySleep {
                    return true
                }
            }
        }

        return false
    }
}
