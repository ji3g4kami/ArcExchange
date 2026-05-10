import SwiftUI

struct ErrorBanner: View {
    let message: String
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
                .lineLimit(2)
            Spacer(minLength: 8)
            Button {
                onRetry()
            } label: {
                Text("Retry")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().stroke(.white, lineWidth: 1.5)
                    )
            }
            .accessibilityIdentifier(A11yID.retryButton)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(Color.red)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(A11yID.errorBanner)
        .onTapGesture(count: 2) { onDismiss() }
    }
}

#Preview {
    ErrorBanner(
        message: "Network unavailable",
        onRetry: {},
        onDismiss: {}
    )
    .padding()
}

#Preview("Dark") {
    ErrorBanner(
        message: "Network unavailable",
        onRetry: {},
        onDismiss: {}
    )
    .padding()
    .preferredColorScheme(.dark)
}
