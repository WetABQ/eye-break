import SwiftUI

struct SettingsView: View {
    let settings: AppSettings
    var onPreviewBreak: (() -> Void)? = nil

    @State private var workMinutes: Double = 20
    @State private var breakSeconds: Double = 20
    @State private var idleSeconds: Double = 30

    var body: some View {
        Form {
            Section("Timing") {
                HStack {
                    Text("Work Duration")
                    Spacer()
                    Text("\(Int(workMinutes)) min")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $workMinutes, in: 5...60, step: 5) {
                    Text("Work Duration")
                }
                .onChange(of: workMinutes) { _, newVal in
                    settings.workDuration = newVal * 60
                }

                HStack {
                    Text("Break Duration")
                    Spacer()
                    Text("\(Int(breakSeconds)) sec")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $breakSeconds, in: 5...120, step: 5) {
                    Text("Break Duration")
                }
                .onChange(of: breakSeconds) { _, newVal in
                    settings.breakDuration = newVal
                }

                HStack {
                    Text("Idle Threshold")
                    Spacer()
                    Text("\(Int(idleSeconds)) sec")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $idleSeconds, in: 10...120, step: 5) {
                    Text("Idle Threshold")
                }
                .onChange(of: idleSeconds) { _, newVal in
                    settings.idleThreshold = newVal
                }
            }

            Section("Menu Bar") {
                Toggle("Show Live Timer", isOn: Binding(
                    get: { settings.showLiveTimer },
                    set: { settings.showLiveTimer = $0 }
                ))
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
        .frame(width: 380, height: 420)
        .onAppear {
            workMinutes = settings.workDuration / 60
            breakSeconds = settings.breakDuration
            idleSeconds = settings.idleThreshold
        }
    }
}
