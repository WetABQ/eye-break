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
        .frame(width: 520, height: 420)
        .onAppear {
            workMinutes = settings.workDuration / 60
            breakSeconds = settings.breakDuration
            idleSeconds = settings.idleThreshold
        }
    }
}
