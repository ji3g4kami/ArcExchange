import Foundation

enum CurrencyConverter {
    /// Convert between USDc and a foreign currency using the bid/ask side
    /// appropriate to the direction. The user always lands on the worse end
    /// of the spread — selling USDc happens at the market's bid; buying USDc
    /// happens at the market's ask.
    static func convert(amount: Decimal, bid: Decimal, ask: Decimal, direction: ConversionDirection) -> Decimal {
        switch direction {
        case .fromUSDc:
            guard bid > 0 else { return 0 }
            return amount * bid
        case .toUSDc:
            guard ask > 0 else { return 0 }
            return amount / ask
        }
    }
}
