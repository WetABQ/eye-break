import Cocoa
import SwiftUI

/// Borderless NSWindow that can become key, ensuring orderFrontRegardless()
/// works reliably even for accessory-policy apps.
private class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class OverlayWindowManager {
    private var windows: [NSWindow] = []
    private var screenObserver: Any?

    var onSkip: (() -> Void)?

    func showOverlay(appState: AppState) {
        removeAllWindows()

        // Temporarily become a regular app so we can reliably activate
        // and bring overlay windows to the front. On macOS 14+,
        // activate(ignoringOtherApps:) is silently ignored for .accessory
        // apps that were never foregrounded.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        for screen in NSScreen.screens {
            let window = createOverlayWindow(for: screen, appState: appState)
            window.orderFrontRegardless()
            windows.append(window)
        }

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenChange(appState: appState)
        }
    }

    func hideOverlay() {
        removeAllWindows()
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
            screenObserver = nil
        }
        // Restore accessory policy so the app hides from the Dock.
        // The Dock icon was invisible anyway during the break because
        // the overlay covers all screens.
        NSApp.setActivationPolicy(.accessory)
    }

    private func createOverlayWindow(for screen: NSScreen, appState: AppState) -> NSWindow {
        let window = OverlayWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = false
        window.setFrame(screen.frame, display: true)

        let overlayView = BreakOverlayView(appState: appState) { [weak self] in
            self?.onSkip?()
        }
        window.contentView = NSHostingView(rootView: overlayView)

        return window
    }

    private func handleScreenChange(appState: AppState) {
        let existingFrames = windows.map { $0.frame }
        let currentScreenFrames = NSScreen.screens.map { $0.frame }

        windows.removeAll { window in
            if !currentScreenFrames.contains(window.frame) {
                window.close()
                return true
            }
            return false
        }

        for screen in NSScreen.screens {
            if !existingFrames.contains(screen.frame) {
                let window = createOverlayWindow(for: screen, appState: appState)
                window.makeKeyAndOrderFront(nil)
                windows.append(window)
            }
        }
    }

    private func removeAllWindows() {
        for window in windows {
            window.close()
        }
        windows.removeAll()
    }

    deinit {
        hideOverlay()
    }
}
