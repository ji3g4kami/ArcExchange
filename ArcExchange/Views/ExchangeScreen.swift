import SwiftUI

struct ExchangeScreen: View {
    @Bindable var viewModel: ExchangeViewModel
    @State private var showPicker = false

    var body: some View {
        ZStack(alignment: .top) {
            backgroundGradient.ignoresSafeArea()
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

            VStack(spacing: 12) {
                if viewModel.usdcOnTop {
                    usdcRow
                    swapBar
                    foreignRow
                } else {
                    foreignRow
                    swapBar
                    usdcRow
                }
            }
            .padding(.top, 8)

            if let updated = viewModel.lastUpdated {
                Text("Updated \(updated, style: .relative) ago")
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
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .animation(.snappy(duration: 0.3), value: viewModel.usdcOnTop)
    }

    private var usdcRow: some View {
        CurrencyFieldView(
            currency: .usdc,
            amount: $viewModel.usdcInput,
            labelIdentifier: A11yID.usdcLabel,
            fieldIdentifier: A11yID.usdcField,
            onCurrencyTap: nil,
            onAmountChange: { viewModel.didEditUSDc($0) }
        )
    }

    private var foreignRow: some View {
        CurrencyFieldView(
            currency: viewModel.selectedCurrency,
            amount: $viewModel.foreignInput,
            labelIdentifier: A11yID.foreignLabel,
            fieldIdentifier: A11yID.foreignField,
            onCurrencyTap: { showPicker = true },
            onAmountChange: { viewModel.didEditForeign($0) }
        )
    }

    private var swapBar: some View {
        ZStack {
            Divider()
            SwapButton {
                viewModel.swap()
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Exchange")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("Convert USDc to your local currency")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(uiColor: .systemBackground), Color.accentColor.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
