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
        self.selectedCurrency = Currency.resolve("MXN")
    }

    private static let rateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        return formatter
    }()

    /// The rate side the user is actually transacting at. Determined by the
    /// swap direction: selling USDc fills foreign at the market's bid;
    /// buying USDc costs the market's ask. Both `.fromUSDc` and `.toUSDc`
    /// editor directions read from the same active side — only `swap()`
    /// changes which side that is.
    private var activeRate: Decimal? {
        guard let rate else { return nil }
        let side = usdcOnTop ? rate.bid : rate.ask
        return side > 0 ? side : nil
    }

    var formattedRate: String? {
        guard let activeRate else { return nil }
        guard let value = Self.rateFormatter.string(from: activeRate as NSDecimalNumber) else { return nil }
        return "1 USDc = \(value) \(selectedCurrency.code)"
    }

    func bootstrap() async {
        async let codesFetch = CurrencyCatalog.load(using: service)
        async let initialRefresh: Void = performRefresh(for: selectedCurrency.apiCode)

        let codes = await codesFetch
        availableCurrencies = codes.map(Currency.resolve)
        await initialRefresh

        if !availableCurrencies.contains(where: { $0.code == selectedCurrency.code }),
           let first = availableCurrencies.first {
            selectedCurrency = first
            await refresh()
        }
    }

    func refresh() async {
        refreshTask?.cancel()
        let code = selectedCurrency.apiCode
        let task = Task {
            await self.performRefresh(for: code)
        }
        refreshTask = task
        await task.value
    }

    private func performRefresh(for code: String) async {
        state = .loading
        do {
            let tickers = try await service.tickers(for: [code])
            try Task.checkCancellation()
            guard let ticker = tickers.first(where: { $0.book.uppercased().hasSuffix("_\(code)") })
                  ?? tickers.first,
                  let newRate = ExchangeRate(ticker: ticker) else {
                state = .failed("No rate available")
                clearAmountsIfNoRate()
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
            clearAmountsIfNoRate()
        }
    }

    func selectCurrency(_ currency: Currency) async {
        guard currency.code != selectedCurrency.code else { return }
        selectedCurrency = currency
        rate = nil
        lastUpdated = nil
        await refresh()
    }

    func swap() {
        // Visual flip only. `activeEditor` follows the user's typed field
        // (set by `userEditedUSDc/Foreign`), so leaving it untouched is what
        // lets a double-swap recover the original numbers — flipping it
        // here would make each swap "forget" which field was the input.
        usdcOnTop.toggle()
        recompute(otherFor: activeEditor)
    }

    func userEditedUSDc() {
        activeEditor = .fromUSDc
        recompute(otherFor: .fromUSDc)
    }

    func userEditedForeign() {
        activeEditor = .toUSDc
        recompute(otherFor: .toUSDc)
    }

    func dismissError() {
        if case .failed = state { state = .loaded }
    }

    private func recomputeFromActiveEditor() {
        recompute(otherFor: activeEditor)
    }

    private func clearAmountsIfNoRate() {
        guard rate == nil else { return }
        if usdcAmount != nil { usdcAmount = nil }
        if foreignAmount != nil { foreignAmount = nil }
    }

    private func recompute(otherFor active: ConversionDirection) {
        guard let activeRate else { return }
        switch active {
        case .fromUSDc:
            guard let amount = usdcAmount else {
                if foreignAmount != nil { foreignAmount = nil }
                return
            }
            let next = CurrencyConverter.convert(amount: amount, rate: activeRate, direction: .fromUSDc)
            if foreignAmount != next { foreignAmount = next }
        case .toUSDc:
            guard let amount = foreignAmount else {
                if usdcAmount != nil { usdcAmount = nil }
                return
            }
            let next = CurrencyConverter.convert(amount: amount, rate: activeRate, direction: .toUSDc)
            if usdcAmount != next { usdcAmount = next }
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
