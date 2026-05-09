import SwiftUI

struct SwapButton: View {
    let action: () -> Void
    @State private var rotation: Double = 0

    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.3)) {
                rotation += 180
            }
            action()
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(Color.accentColor)
                )
                .rotationEffect(.degrees(rotation))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(A11yID.swapButton)
        .accessibilityLabel("Swap currencies")
    }
}
