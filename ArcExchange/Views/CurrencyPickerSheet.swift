import SwiftUI

struct CurrencyPickerSheet: View {
    let currencies: [Currency]
    let selected: Currency
    let onSelect: (Currency) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            header

            VStack(spacing: 0) {
                ForEach(currencies) { currency in
                    Button {
                        onSelect(currency)
                        dismiss()
                    } label: {
                        row(for: currency)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(A11yID.pickerRow(currency.code))
                }
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .padding(.top, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.pageBackground)
        .accessibilityIdentifier(A11yID.pickerSheet)
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.pageBackground)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Choose currency")
                .font(.system(size: 24, weight: .bold))
                .kerning(-0.48)
                .foregroundStyle(.primary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 16)
    }

    private func row(for currency: Currency) -> some View {
        HStack(spacing: 16) {
            flagChip(for: currency)
            Text(currency.code)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
            Spacer()
            selectionIndicator(isSelected: currency.code == selected.code)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .frame(minHeight: 58)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func flagChip(for currency: Currency) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.flagChipBackground)
            if let asset = currency.flagAssetName {
                Image(asset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            } else {
                Text(currency.flag)
                    .font(.system(size: 22))
            }
        }
        .frame(width: 40, height: 40)
    }

    @ViewBuilder
    private func selectionIndicator(isSelected: Bool) -> some View {
        if isSelected {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.brandGreen))
        } else {
            Circle()
                .strokeBorder(Color.radioBorder, lineWidth: 1.5)
                .frame(width: 24, height: 24)
        }
    }
}

private extension Color {
    static let flagChipBackground = Color(red: 0xF4 / 255, green: 0xF4 / 255, blue: 0xF4 / 255)
    static let radioBorder = Color(red: 0xD4 / 255, green: 0xD4 / 255, blue: 0xD4 / 255)
}
