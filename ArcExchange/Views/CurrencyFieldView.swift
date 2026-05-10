import SwiftUI

struct CurrencyFieldView: View {
    let currency: Currency
    @Binding var amount: Decimal?
    let labelIdentifier: String
    let fieldIdentifier: String
    let onCurrencyTap: (() -> Void)?
    var isInputDisabled: Bool = false

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
                    if onCurrencyTap != nil {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
                .fixedSize()
            }
            .buttonStyle(.plain)
            .disabled(onCurrencyTap == nil)
            .accessibilityIdentifier(labelIdentifier)

            Spacer(minLength: 8)

            HStack(spacing: 2) {
                Text("$")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(amount == nil ? Color.secondary : Color.primary)
                TextField("0", value: $amount, format: amountFormat)
                    .multilineTextAlignment(.leading)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .fixedSize()
                    .disabled(isInputDisabled)
                    .accessibilityIdentifier(fieldIdentifier)
            }
            .opacity(isInputDisabled ? 0.4 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 22)
        .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 16))
    }

    private var amountFormat: Decimal.FormatStyle {
        .number
            .precision(.fractionLength(0...currency.fractionDigitLimit))
            .grouping(.automatic)
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
    @Previewable @State var amount: Decimal? = 100
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
    @Previewable @State var amount: Decimal? = 100
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
    @Previewable @State var amount: Decimal? = nil
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
    @Previewable @State var amount: Decimal? = nil
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
