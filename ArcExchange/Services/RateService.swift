import Foundation

protocol RateService: Sendable {
    func tickers(for currencyCodes: [String]) async throws -> [Ticker]
    func availableCurrencies() async throws -> [String]
}
