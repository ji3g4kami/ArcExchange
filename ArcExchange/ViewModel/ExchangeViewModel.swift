import Foundation
import Observation

@MainActor
@Observable
final class ExchangeViewModel {
    private let service: any RateService

    var state: LoadState = .idle
    var availableCurrencies: [Currency] = Currency.fallback
    var selectedCurrency: Currency
    var rate: ExchangeRate?
    var usdcAmount: Decimal? = nil
    var foreignAmount: Decimal? = nil
    var activeEditor: ConversionDirection = .fromUSDc
    var lastUpdated: Date?
    var usdcOnTop: Bool = true

    private var refreshTask: Task<Void, Never>?

    init(service: any RateService) {
        self.service = service
        self.selectedCurrency = Currency.fallback.first ?? Currency.resolve("MXN")
    }

    var formattedRate: String? {
        guard let mid = rate?.mid, mid > 0 else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        guard let value = formatter.string(from: mid as NSDecimalNumber) else { return nil }
        return "1 USDc = \(value) \(selectedCurrency.code)"
    }

    func bootstrap() async {
        let codes = await CurrencyCatalog.load(using: service)
        availableCurrencies = codes.map(Currency.resolve)
        if !availableCurrencies.contains(where: { $0.code == selectedCurrency.code }),
           let first = availableCurrencies.first {
            selectedCurrency = first
        }
        await refresh()
    }

    func refresh() async {
        refreshTask?.cancel()
        let code = selectedCurrency.code
        let task = Task { [service] in
            await self.performRefresh(for: code, using: service)
        }
        refreshTask = task
        await task.value
    }

    private func performRefresh(for code: String, using service: any RateService) async {
        state = .loading
        do {
            let tickers = try await service.tickers(for: [code])
            try Task.checkCancellation()
            guard let ticker = tickers.first(where: { $0.book.uppercased().hasSuffix("_\(code)") })
                  ?? tickers.first,
                  let newRate = ExchangeRate(ticker: ticker) else {
                state = .failed("No rate available")
                return
            }
            rate = newRate
            lastUpdated = Date()
            state = .loaded
            recomputeFromActiveEditor()
        } catch is CancellationError {
            return
        } catch {
            state = .failed(humanReadable(error))
        }
    }

    func selectCurrency(_ currency: Currency) async {
        guard currency.code != selectedCurrency.code else { return }
        selectedCurrency = currency
        await refresh()
    }

    func swap() {
        usdcOnTop.toggle()
        activeEditor = (activeEditor == .fromUSDc) ? .toUSDc : .fromUSDc
    }

    func didEditUSDc(_ value: Decimal?) {
        usdcAmount = value
        activeEditor = .fromUSDc
        recompute(otherFor: .fromUSDc)
    }

    func didEditForeign(_ value: Decimal?) {
        foreignAmount = value
        activeEditor = .toUSDc
        recompute(otherFor: .toUSDc)
    }

    func dismissError() {
        if case .failed = state { state = .loaded }
    }

    private func recomputeFromActiveEditor() {
        recompute(otherFor: activeEditor)
    }

    private func recompute(otherFor active: ConversionDirection) {
        guard let mid = rate?.mid, mid > 0 else { return }
        switch active {
        case .fromUSDc:
            guard let amount = usdcAmount else {
                foreignAmount = nil
                return
            }
            foreignAmount = CurrencyConverter.convert(amount: amount, mid: mid, direction: .fromUSDc)
        case .toUSDc:
            guard let amount = foreignAmount else {
                usdcAmount = nil
                return
            }
            usdcAmount = CurrencyConverter.convert(amount: amount, mid: mid, direction: .toUSDc)
        }
    }

    private func humanReadable(_ error: Error) -> String {
        if let serviceError = error as? RateServiceError {
            switch serviceError {
            case .invalidURL: return "Invalid URL"
            case .http(let code): return "Server error (\(code))"
            case .decoding: return "Couldn't read response"
            case .transport: return "Network unavailable"
            }
        }
        return "Something went wrong"
    }
}
