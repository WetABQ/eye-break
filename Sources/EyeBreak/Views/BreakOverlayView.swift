import SwiftUI

struct BreakOverlayView: View {
    let appState: AppState
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.92)

            VStack(spacing: 30) {
                Image(systemName: "eye")
                    .font(.system(size: 64))
                    .foregroundStyle(.white.opacity(0.8))

                Text("Time to Rest Your Eyes")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Look at something 20 feet away")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.7))

                Text(appState.formattedRemaining)
                    .font(.system(size: 80, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.top, 10)

                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: breakProgress)
                        .stroke(.white.opacity(0.8), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: breakProgress)
                }
                .frame(width: 120, height: 120)

                Button(action: onSkip) {
                    Text("Skip")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 20)
            }
        }
        .ignoresSafeArea()
    }

    private var breakProgress: Double {
        guard let settings = appState.settings, settings.breakDuration > 0 else { return 0 }
        return max(0, 1.0 - appState.remainingBreak / settings.breakDuration)
    }
}
