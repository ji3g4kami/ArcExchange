import SwiftUI

struct CurrencyFieldView: View {
    let currency: Currency
    @Binding var amount: Decimal?
    let labelIdentifier: String
    let fieldIdentifier: String
    let onCurrencyTap: (() -> Void)?
    let onAmountChange: (Decimal?) -> Void

    private static let maxAmount = Decimal(string: "999999999999")!

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
                    .accessibilityIdentifier(fieldIdentifier)
                    .onChange(of: amount) { oldValue, newValue in
                        if let new = newValue, new > Self.maxAmount {
                            amount = oldValue
                            return
                        }
                        onAmountChange(newValue)
                    }
            }
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
            Text(currency.flag)
                .font(.system(size: 16))
        }
    }
}
