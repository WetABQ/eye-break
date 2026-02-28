import IOKit.pwr_mgt

final class MediaPlaybackMonitor {
    /// Returns `true` if any process holds a `PreventUserIdleDisplaySleep` assertion,
    /// indicating active media playback (browsers, VLC, QuickTime, streaming apps, etc.).
    func isMediaPlaying() -> Bool {
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
