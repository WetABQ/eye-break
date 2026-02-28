import SwiftUI

extension View {
    @ViewBuilder
    func adaptiveGlassBackground() -> some View {
        #if compiler(>=6.1)
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular, in: .rect(cornerRadius: 10))
        } else {
            self
                .background(VisualEffectBackground())
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        #else
        self
            .background(VisualEffectBackground())
            .clipShape(RoundedRectangle(cornerRadius: 10))
        #endif
    }

    @ViewBuilder
    func skipButtonBackground() -> some View {
        #if compiler(>=6.1)
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular, in: .capsule)
        } else {
            self
                .background(.white.opacity(0.1))
                .clipShape(Capsule())
        }
        #else
        self
            .background(.white.opacity(0.1))
            .clipShape(Capsule())
        #endif
    }
}
