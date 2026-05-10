import SwiftUI
import UIKit

struct ExchangeScreen: View {
    @Bindable var viewModel: ExchangeViewModel
    @State private var showPicker = false

    var body: some View {
        ZStack(alignment: .top) {
            Color("PageBackground").ignoresSafeArea()
            ScrollView {
                content
            }
            .scrollDismissesKeyboard(.interactively)
            .refreshable {
                await viewModel.refresh()
            }
        }
        .task {
            if viewModel.state == .idle {
                await viewModel.bootstrap()
            }
        }
        .sheet(isPresented: $showPicker) {
            CurrencyPickerSheet(
                currencies: viewModel.availableCurrencies,
                selected: viewModel.selectedCurrency,
                onSelect: { currency in
                    Task { await viewModel.selectCurrency(currency) }
                }
            )
        }
    }

    private var content: some View {
        VStack(spacing: 16) {
            header

            ZStack {
                VStack(spacing: 8) {
                    if viewModel.usdcOnTop {
                        usdcRow
                        foreignRow
                    } else {
                        foreignRow
                        usdcRow
                    }
                }
                SwapButton {
                    viewModel.swap()
                }
            }
            .padding(.top, 8)

            if let updated = viewModel.lastUpdated {
                Text("Updated at \(updated, style: .time)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier(A11yID.lastUpdated)
            }

            if case .failed(let message) = viewModel.state {
                ErrorBanner(
                    message: message,
                    onRetry: { Task { await viewModel.refresh() } },
                    onDismiss: { viewModel.dismissError() }
                )
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .animation(.snappy(duration: 0.3), value: viewModel.usdcOnTop)
    }

    private var usdcRow: some View {
        CurrencyFieldView(
            currency: .usdc,
            amount: $viewModel.usdcAmount,
            labelIdentifier: A11yID.usdcLabel,
            fieldIdentifier: A11yID.usdcField,
            onCurrencyTap: nil,
            isInputDisabled: viewModel.rate == nil,
            onUserEdit: { viewModel.userEditedUSDc() }
        )
    }

    private var foreignRow: some View {
        CurrencyFieldView(
            currency: viewModel.selectedCurrency,
            amount: $viewModel.foreignAmount,
            labelIdentifier: A11yID.foreignLabel,
            fieldIdentifier: A11yID.foreignField,
            onCurrencyTap: { openPicker() },
            isInputDisabled: viewModel.rate == nil,
            onUserEdit: { viewModel.userEditedForeign() }
        )
    }

    private func openPicker() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
        )
        showPicker = true
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Exchange calculator")
                    .font(.system(size: 30, weight: .bold))
                    .kerning(-0.6)
                    .foregroundStyle(Color.primary)
                if let formatted = viewModel.formattedRate {
                    Text(formatted)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color("BrandGreen"))
                        .accessibilityIdentifier(A11yID.rateLine)
                }
            }
            Spacer()
        }
    }
}

#Preview("Loaded") {
    ExchangeScreen(viewModel: .previewLoaded)
}

#Preview("Loaded · Dark") {
    ExchangeScreen(viewModel: .previewLoaded)
        .preferredColorScheme(.dark)
}

#Preview("Failed") {
    ExchangeScreen(viewModel: .previewFailed)
}

#Preview("Failed · Dark") {
    ExchangeScreen(viewModel: .previewFailed)
        .preferredColorScheme(.dark)
}

#Preview("Loading") {
    ExchangeScreen(viewModel: .previewLoading)
}

#Preview("Loading · Dark") {
    ExchangeScreen(viewModel: .previewLoading)
        .preferredColorScheme(.dark)
}
