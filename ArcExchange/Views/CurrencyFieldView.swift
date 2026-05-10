import SwiftUI

struct CurrencyFieldView: View {
    let currency: Currency
    @Binding var amount: Decimal?
    let labelIdentifier: String
    let fieldIdentifier: String
    let onCurrencyTap: (() -> Void)?
    var isInputDisabled: Bool = false

    @State private var isFocused: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onCurrencyTap?()
            } label: {
                HStack(spacing: 8) {
                    flagView
                    Text(currency.code)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .frame(width: 50, alignment: .leading)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                        .opacity(onCurrencyTap == nil ? 0 : 1)
                }
                .fixedSize()
            }
            .buttonStyle(.plain)
            .disabled(onCurrencyTap == nil)
            .accessibilityIdentifier(labelIdentifier)

            Spacer(minLength: 8)

            Group {
                if isFocused {
                    AmountTextField(
                        amount: $amount,
                        isFocused: $isFocused,
                        fractionDigitLimit: currency.fractionDigitLimit,
                        placeholder: "0",
                        isEnabled: !isInputDisabled,
                        accessibilityIdentifier: fieldIdentifier
                    )
                    .disabled(isInputDisabled)
                } else {
                    Text("$\(displayedAmount)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(amount == nil ? Color.secondary : Color.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(10.0 / 16.0)
                        .truncationMode(.middle)
                        .multilineTextAlignment(.trailing)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier(fieldIdentifier)
                        .accessibilityValue(displayedAmount)
                        .disabled(isInputDisabled)
                        .onTapGesture {
                            if !isInputDisabled { isFocused = true }
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .opacity(isInputDisabled ? 0.4 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 22)
        .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 16))
    }

    private var displayedAmount: String {
        let text = AmountInput.displayGrouped(
            forAmount: amount,
            fractionDigitLimit: currency.fractionDigitLimit
        )
        return text.isEmpty ? "0" : text
    }

    @ViewBuilder
    private var flagView: some View {
        if let asset = currency.flagAssetName {
            Image(asset)
                .resizable()
                .scaledToFill()
                .frame(width: 20, height: 20)
                .clipShape(Circle())
        } else {
            Image(systemName: "globe")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)
        }
    }
}

#Preview("USDc · enabled") {
    @Previewable @State var amount: Decimal? = 12345
    CurrencyFieldView(
        currency: .usdc,
        amount: $amount,
        labelIdentifier: "preview.label",
        fieldIdentifier: "preview.field",
        onCurrencyTap: nil
    )
    .padding()
    .background(Color("PageBackground"))
}

#Preview("USDc · enabled · Dark") {
    @Previewable @State var amount: Decimal? = 12345
    CurrencyFieldView(
        currency: .usdc,
        amount: $amount,
        labelIdentifier: "preview.label",
        fieldIdentifier: "preview.field",
        onCurrencyTap: nil
    )
    .padding()
    .background(Color("PageBackground"))
    .preferredColorScheme(.dark)
}

#Preview("Foreign · enabled") {
    @Previewable @State var amount: Decimal? = 227142
    CurrencyFieldView(
        currency: Currency.resolve("MXN"),
        amount: $amount,
        labelIdentifier: "preview.label",
        fieldIdentifier: "preview.field",
        onCurrencyTap: {}
    )
    .padding()
    .background(Color("PageBackground"))
}

#Preview("Foreign · enabled · Dark") {
    @Previewable @State var amount: Decimal? = 227142
    CurrencyFieldView(
        currency: Currency.resolve("MXN"),
        amount: $amount,
        labelIdentifier: "preview.label",
        fieldIdentifier: "preview.field",
        onCurrencyTap: {}
    )
    .padding()
    .background(Color("PageBackground"))
    .preferredColorScheme(.dark)
}

#Preview("Foreign · disabled (no rate)") {
    CurrencyFieldView(
        currency: Currency.resolve("MXN"),
        amount: .constant(nil),
        labelIdentifier: "preview.label",
        fieldIdentifier: "preview.field",
        onCurrencyTap: {},
        isInputDisabled: true
    )
    .padding()
    .background(Color("PageBackground"))
}

#Preview("Foreign · disabled · Dark") {
    CurrencyFieldView(
        currency: Currency.resolve("MXN"),
        amount: .constant(nil),
        labelIdentifier: "preview.label",
        fieldIdentifier: "preview.field",
        onCurrencyTap: {},
        isInputDisabled: true
    )
    .padding()
    .background(Color("PageBackground"))
    .preferredColorScheme(.dark)
}
