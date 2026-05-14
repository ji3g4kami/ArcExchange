#if DEBUG
import Foundation

struct PreviewRateService: RateService {
    var tickersResult: Result<[Ticker], Error> = .success([])
    var currenciesResult: Result<[String], Error> = .success(Currency.fallbackCodes)

    func tickers(for codes: [String]) async throws -> [Ticker] {
        try tickersResult.get()
    }

    func availableCurrencies() async throws -> [String] {
        try currenciesResult.get()
    }
}

@MainActor
extension ExchangeViewModel {
    static var previewLoaded: ExchangeViewModel {
        let vm = ExchangeViewModel(service: PreviewRateService())
        vm.state = .loaded
        let ticker = Ticker(
            ask: Decimal(string: "18.4105")!,
            bid: Decimal(string: "18.4070")!,
            book: "usdc_mxn"
        )
        vm.rate = ExchangeRate(ticker: ticker)
        vm.lastUpdated = Date()
        vm.usdcAmount = 100
        vm.foreignAmount = 1840
        return vm
    }

    static var previewFailed: ExchangeViewModel {
        let vm = ExchangeViewModel(service: PreviewRateService())
        vm.state = .failed("Network unavailable")
        return vm
    }

    static var previewLoading: ExchangeViewModel {
        let vm = ExchangeViewModel(service: PreviewRateService())
        vm.state = .loading
        return vm
    }
}
#endif
