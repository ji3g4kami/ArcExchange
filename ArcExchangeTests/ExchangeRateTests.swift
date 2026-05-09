import Foundation
import Testing
@testable import ArcExchange

struct ExchangeRateTests {

    @Test
    func mid_is_exact_average_of_bid_and_ask() throws {
        let ticker = Ticker(
            ask: Decimal(string: "18.4105")!,
            bid: Decimal(string: "18.40697")!,
            book: "usdc_mxn",
            date: Date(timeIntervalSince1970: 0)
        )

        let rate = try #require(ExchangeRate(ticker: ticker))
        let expectedMid = (Decimal(string: "18.4105")! + Decimal(string: "18.40697")!) / 2
        #expect(rate.mid == expectedMid)
        #expect(rate.currencyCode == "MXN")
    }

    @Test
    func parses_currency_code_from_book_uppercased() throws {
        let ticker = Ticker(
            ask: Decimal(1551),
            bid: Decimal(string: "1539.42903")!,
            book: "usdc_ars",
            date: Date(timeIntervalSince1970: 0)
        )
        let rate = try #require(ExchangeRate(ticker: ticker))
        #expect(rate.currencyCode == "ARS")
    }

    @Test
    func nil_when_book_format_unexpected() {
        let ticker = Ticker(
            ask: 1,
            bid: 1,
            book: "weird-book-no-underscore",
            date: Date(timeIntervalSince1970: 0)
        )
        #expect(ExchangeRate(ticker: ticker) == nil)
    }

    @Test
    func nil_when_book_does_not_start_with_usdc() {
        let ticker = Ticker(
            ask: 1,
            bid: 1,
            book: "btc_mxn",
            date: Date(timeIntervalSince1970: 0)
        )
        #expect(ExchangeRate(ticker: ticker) == nil)
    }
}
