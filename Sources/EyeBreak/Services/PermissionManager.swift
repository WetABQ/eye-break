import Cocoa
import ApplicationServices

@Observable
final class PermissionManager {
    private var pollTimer: Timer?

    var isTrusted: Bool = false

    /// Pure read-only check. Never triggers any system UI.
    func check() -> Bool {
        isTrusted = AXIsProcessTrusted()
        return isTrusted
    }

    /// User-initiated: opens the system prompt to grant permission.
    /// Only call this from a button action, never automatically.
    func promptForPermission() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
    }

    /// Opens System Settings > Accessibility directly.
    func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Poll every 2s until permission is granted, then call onGranted once.
    func startPolling(onGranted: @escaping () -> Void) {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: Constants.permissionPollInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.check() {
                self.stopPolling()
                onGranted()
            }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
}
