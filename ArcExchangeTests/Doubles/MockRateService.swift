import Foundation
@testable import ArcExchange

actor MockRateService: RateService {
    private(set) var tickerCalls: [[String]] = []
    private(set) var currencyCallCount: Int = 0

    private var tickerResult: Result<[Ticker], Error> = .success([])
    private var currencyResult: Result<[String], Error> = .success([])
    private var tickerDelay: Duration = .zero

    func setTickerResult(_ result: Result<[Ticker], Error>) {
        self.tickerResult = result
    }

    func setCurrencyResult(_ result: Result<[String], Error>) {
        self.currencyResult = result
    }

    func setTickerDelay(_ delay: Duration) {
        self.tickerDelay = delay
    }

    func tickers(for currencyCodes: [String]) async throws -> [Ticker] {
        tickerCalls.append(currencyCodes)
        if tickerDelay > .zero {
            try await Task.sleep(for: tickerDelay)
        }
        return try tickerResult.get()
    }

    func availableCurrencies() async throws -> [String] {
        currencyCallCount += 1
        return try currencyResult.get()
    }
}
