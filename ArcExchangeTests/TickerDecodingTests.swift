import Foundation
import Testing
@testable import ArcExchange

struct TickerDecodingTests {

    @Test
    func decodes_array_of_two_tickers_from_fixture() throws {
        let decoder = JSONDecoder.dolarApp
        let tickers = try decoder.decode([Ticker].self, from: TickersFixture.twoTickersData)
        #expect(tickers.count == 2)
        #expect(tickers[0].book == "usdc_mxn")
        #expect(tickers[1].book == "usdc_ars")
    }

    @Test
    func decodes_ask_and_bid_as_decimal_preserving_full_precision() throws {
        let decoder = JSONDecoder.dolarApp
        let tickers = try decoder.decode([Ticker].self, from: TickersFixture.twoTickersData)

        #expect(tickers[0].ask == Decimal(string: "18.4105")!)
        #expect(tickers[0].bid == Decimal(string: "18.40697")!)
        #expect(tickers[1].ask == Decimal(string: "1551")!)
        #expect(tickers[1].bid == Decimal(string: "1539.42903")!)
    }

    @Test
    func decodes_iso8601_date_with_fractional_seconds() throws {
        let decoder = JSONDecoder.dolarApp
        let tickers = try decoder.decode([Ticker].self, from: TickersFixture.twoTickersData)

        var components = DateComponents()
        components.year = 2025
        components.month = 10
        components.day = 20
        components.hour = 20
        components.minute = 14
        components.second = 57
        components.timeZone = TimeZone(secondsFromGMT: 0)
        let expected = Calendar(identifier: .gregorian).date(from: components)!

        let interval = tickers[0].date.timeIntervalSince(expected)
        #expect(abs(interval) < 1.0)
    }
}
