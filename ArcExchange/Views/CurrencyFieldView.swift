import SwiftUI

struct CurrencyFieldView: View {
    let currency: Currency
    @Binding var amount: String
    let labelIdentifier: String
    let fieldIdentifier: String
    let onCurrencyTap: (() -> Void)?
    let onAmountChange: (String) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onCurrencyTap?()
            } label: {
                HStack(spacing: 8) {
                    Text(currency.flag)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currency.code)
                            .font(.headline)
                        Text(currency.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if onCurrencyTap != nil {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(onCurrencyTap == nil)
            .accessibilityIdentifier(labelIdentifier)

            Spacer(minLength: 4)

            TextField("0", text: $amount)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .accessibilityIdentifier(fieldIdentifier)
                .onChange(of: amount) { _, newValue in
                    onAmountChange(newValue)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
        )
    }
}
