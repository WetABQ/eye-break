import Foundation
import IOKit.pwr_mgt

final class MediaPlaybackMonitor {
    private var cachedResult = false
    private var lastCheckTime: TimeInterval = 0
    private let cacheInterval: TimeInterval = 5

    /// Returns `true` if any process holds a `PreventUserIdleDisplaySleep` assertion,
    /// indicating active media playback (browsers, VLC, QuickTime, streaming apps, etc.).
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

        for (_, assertions) in dict {
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
