import SwiftUI
import ServiceManagement

struct SettingsView: View {
    let settings: AppSettings
    var onPreviewBreak: (() -> Void)? = nil

    @State private var workMinutes: Double = 20
    @State private var breakSeconds: Double = 20
    @State private var idleSeconds: Double = 30
    @State private var launchAtLogin: Bool = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section("Timing") {
                HStack {
                    Text("Work Duration")
                        .frame(width: 100, alignment: .leading)
                    Slider(value: $workMinutes, in: 5...60, step: 5)
                        .onChange(of: workMinutes) { _, newVal in
                            settings.workDuration = newVal * 60
                        }
                    Text("\(Int(workMinutes)) min")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(width: 55, alignment: .trailing)
                }

                HStack {
                    Text("Break Duration")
                        .frame(width: 100, alignment: .leading)
                    Slider(value: $breakSeconds, in: 5...120, step: 5)
                        .onChange(of: breakSeconds) { _, newVal in
                            settings.breakDuration = newVal
                        }
                    Text("\(Int(breakSeconds)) sec")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(width: 55, alignment: .trailing)
                }

                HStack {
                    Text("Idle Threshold")
                        .frame(width: 100, alignment: .leading)
                    Slider(value: $idleSeconds, in: 10...120, step: 5)
                        .onChange(of: idleSeconds) { _, newVal in
                            settings.idleThreshold = newVal
                        }
                    Text("\(Int(idleSeconds)) sec")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(width: 55, alignment: .trailing)
                }
            }

            Section("Detection") {
                Toggle("Count media playback as screen time", isOn: Binding(
                    get: { settings.countMediaAsScreenTime },
                    set: { settings.countMediaAsScreenTime = $0 }
                ))
                Text("Triggers eye breaks even while watching videos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Menu Bar") {
                Toggle("Show Live Timer", isOn: Binding(
                    get: { settings.showLiveTimer },
                    set: { settings.showLiveTimer = $0 }
                ))
            }

            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newVal in
                        do {
                            if newVal {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                            loginError = nil
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                            loginError = "Could not update login item automatically. Add EyeBreak manually in System Settings."
                        }
                    }

                if let loginError {
                    Text(loginError)
                        .font(.caption)
                        .foregroundStyle(.orange)

                    Button("Open Login Items in System Settings") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!)
                    }
                    .font(.caption)
                }
            }

            if let onPreviewBreak {
                Section {
                    Button(action: onPreviewBreak) {
                        Label("Preview Break", systemImage: "eye")
                    }
                }
            }

            Section("Info") {
                Text("EyeBreak monitors your screen activity and reminds you to take breaks to protect your eyes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 500)
        .onAppear {
            workMinutes = settings.workDuration / 60
            breakSeconds = settings.breakDuration
            idleSeconds = settings.idleThreshold
        }
    }
}
