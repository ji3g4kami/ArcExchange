import Foundation

struct ExchangeRate: Sendable, Equatable {
    let currencyCode: String
    let bid: Decimal
    let ask: Decimal

    var mid: Decimal { (bid + ask) / 2 }
}

extension ExchangeRate {
    init?(ticker: Ticker) {
        let parts = ticker.book.split(separator: "_")
        guard parts.count == 2, parts[0].lowercased() == "usdc" else { return nil }
        self.currencyCode = parts[1].uppercased()
        self.bid = ticker.bid
        self.ask = ticker.ask
    }
}
