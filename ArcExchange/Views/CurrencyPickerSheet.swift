import SwiftUI

struct CurrencyPickerSheet: View {
    let currencies: [Currency]
    let selected: Currency
    let onSelect: (Currency) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(currencies) { currency in
                Button {
                    onSelect(currency)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text(currency.flag).font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currency.code).font(.headline)
                            Text(currency.displayName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if currency.code == selected.code {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .accessibilityIdentifier(A11yID.pickerRow(currency.code))
            }
            .listStyle(.plain)
            .navigationTitle("Choose currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .accessibilityIdentifier(A11yID.pickerSheet)
        .presentationDetents([.medium, .large])
    }
}
