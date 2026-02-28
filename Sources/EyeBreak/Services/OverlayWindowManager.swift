import Cocoa
import SwiftUI

final class OverlayWindowManager {
    private var windows: [NSWindow] = []
    private var screenObserver: Any?

    var onSkip: (() -> Void)?

    func showOverlay(appState: AppState) {
        removeAllWindows()

        // Temporarily switch to .regular so the app can activate and bring
        // overlay windows to the front even without prior user interaction.
        // On macOS 14+ the ignoringOtherApps parameter of activate() is
        // silently ignored for .accessory apps that were never foregrounded.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        for screen in NSScreen.screens {
            let window = createOverlayWindow(for: screen, appState: appState)
            window.makeKeyAndOrderFront(nil)
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
        // Restore accessory policy so the app hides from the Dock again.
        NSApp.setActivationPolicy(.accessory)
    }

    private func createOverlayWindow(for screen: NSScreen, appState: AppState) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
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
