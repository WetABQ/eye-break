import Cocoa
import SwiftUI

private class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: NSPanel?
    private var settingsWindow: NSWindow?

    private let settings = AppSettings()
    private let appState = AppState()
    private let permissionManager = PermissionManager()
    private let activityMonitor = ActivityMonitor()
    private var overlayManager: OverlayWindowManager!
    private var breakManager: BreakManager!
    private var workTimerService: WorkTimerService!

    private var statusUpdateTimer: Timer?
    private var clickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        ProcessInfo.processInfo.disableAutomaticTermination("Menu bar app")
        ProcessInfo.processInfo.disableSuddenTermination()

        appState.settings = settings
        overlayManager = OverlayWindowManager()
        breakManager = BreakManager(appState: appState, settings: settings, overlayManager: overlayManager)
        workTimerService = WorkTimerService(
            appState: appState,
            settings: settings,
            activityMonitor: activityMonitor,
            breakManager: breakManager
        )

        setupStatusItem()
        checkPermissionAndStart()
        startStatusUpdates()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusItemTitle()

        if let button = statusItem.button {
            button.action = #selector(togglePanel)
            button.target = self
        }
    }

    private func updateStatusItemTitle() {
        guard let button = statusItem.button else { return }

        button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "EyeBreak")

        switch appState.phase {
        case .idle:
            button.title = ""
        case .working:
            button.title = settings.showLiveTimer ? " \(appState.formattedWorkLeft)" : ""
        case .onBreak:
            button.title = settings.showLiveTimer ? " \(appState.formattedRemaining)" : ""
        }
    }

    private func startStatusUpdates() {
        statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateStatusItemTitle()
        }
    }

    // MARK: - Panel (replaces NSPopover)

    @objc private func togglePanel() {
        if let panel, panel.isVisible {
            closePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        let contentView = MenuBarPopoverView(
            appState: appState,
            settings: settings,
            permissionManager: permissionManager,
            onQuit: { NSApp.terminate(nil) },
            onSettings: { [weak self] in
                self?.closePanel()
                self?.openSettings()
            }
        )

        let hostingController = NSHostingController(rootView: contentView)
        // Remove default hosting view background
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = .clear

        let size = hostingController.view.fittingSize

        // Position directly below the status item button
        var origin = NSPoint.zero
        if let button = statusItem.button, let buttonWindow = button.window {
            let buttonFrame = button.convert(button.bounds, to: nil)
            let screenFrame = buttonWindow.convertToScreen(buttonFrame)
            origin.x = screenFrame.midX - size.width / 2
            origin.y = screenFrame.minY - size.height - 4
        }

        let p = KeyablePanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        p.isFloatingPanel = true
        p.level = .popUpMenu
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.isMovableByWindowBackground = false
        p.contentViewController = hostingController

        p.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.panel = p

        // Dismiss when clicking outside
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePanel()
        }
    }

    private func closePanel() {
        panel?.close()
        panel = nil
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
    }

    // MARK: - Settings Window

    private func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(settings: settings, onPreviewBreak: { [weak self] in
            self?.breakManager.startBreak()
        })
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "EyeBreak Settings"
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.settingsWindow = window
    }

    // MARK: - Permission & Start

    private func checkPermissionAndStart() {
        let hasPermission = permissionManager.check()
        appState.hasAccessibilityPermission = hasPermission

        // Always start the timer — CGEventSource-based idle detection
        // works without Accessibility permission.
        workTimerService.start()

        if !hasPermission {
            permissionManager.startPolling { [weak self] in
                self?.appState.hasAccessibilityPermission = true
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        workTimerService.stop()
        permissionManager.stopPolling()
        statusUpdateTimer?.invalidate()
        closePanel()
    }
}
