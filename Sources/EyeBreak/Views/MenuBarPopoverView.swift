import SwiftUI

struct MenuBarPopoverView: View {
    let appState: AppState
    let settings: AppSettings
    let permissionManager: PermissionManager
    let onQuit: () -> Void
    let onSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !appState.hasAccessibilityPermission {
                permissionSection
            } else {
                statusSection
                Divider()
                controlsSection
            }

            Divider()

            HStack {
                Button("Settings...") { onSettings() }
                Spacer()
                Button("Quit") { onQuit() }
            }
            .buttonStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 260)
        .adaptiveGlassBackground()
    }

    // MARK: - Permission

    @ViewBuilder
    private var permissionSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "lock.shield")
                .font(.system(size: 28))
                .foregroundStyle(.orange)

            Text("Accessibility Permission Required")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("EyeBreak needs accessibility access to detect keyboard and mouse activity.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Grant Permission") {
                permissionManager.promptForPermission()
            }
            .buttonStyle(.borderedProminent)

            Button("Open System Settings") {
                permissionManager.openSystemSettings()
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Status

    @ViewBuilder
    private var statusSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle)
                    .font(.headline)
                Text(statusSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            phaseIcon
        }

        if appState.phase == .working {
            ProgressView(value: appState.workProgress)
                .tint(.blue)

            HStack {
                Text("Worked: \(appState.formattedElapsed)")
                Spacer()
                Text("Break in: \(appState.formattedWorkLeft)")
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(.secondary)
        }

        if appState.phase == .onBreak {
            Text("Remaining: \(appState.formattedRemaining)")
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.blue)
        }
    }

    @ViewBuilder
    private var phaseIcon: some View {
        switch appState.phase {
        case .idle:
            Image(systemName: "moon.zzz.fill")
                .foregroundStyle(.gray)
                .font(.title2)
        case .working:
            Image(systemName: "desktopcomputer")
                .foregroundStyle(.blue)
                .font(.title2)
        case .onBreak:
            Image(systemName: "eye")
                .foregroundStyle(.green)
                .font(.title2)
        }
    }

    private var statusTitle: String {
        switch appState.phase {
        case .idle: "Idle"
        case .working: "Working"
        case .onBreak: "On Break"
        }
    }

    private var statusSubtitle: String {
        switch appState.phase {
        case .idle: "Waiting for activity..."
        case .working: "Tracking screen time"
        case .onBreak: "Rest your eyes!"
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private var controlsSection: some View {
        Toggle("Enabled", isOn: Binding(
            get: { settings.isEnabled },
            set: { settings.isEnabled = $0 }
        ))
        .toggleStyle(.switch)
        .tint(.blue)
        .font(.system(size: 13))
    }
}
