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
            Image(systemName: "arrow.down")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color("BrandGreen")))
                .padding(4)
                .background(Circle().fill(Color("PageBackground")))
                .rotationEffect(.degrees(rotation))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(A11yID.swapButton)
        .accessibilityLabel("Swap currencies")
    }
}
