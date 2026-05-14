import Foundation

enum CurrencyConverter {
    /// Convert between USDc and a foreign currency at a single rate. The
    /// rate side (bid vs ask) is picked by the caller based on the
    /// transaction direction — see `ExchangeViewModel.activeRate`.
    static func convert(amount: Decimal, rate: Decimal, direction: ConversionDirection) -> Decimal {
        guard rate > 0 else { return 0 }
        switch direction {
        case .fromUSDc: return amount * rate
        case .toUSDc:   return amount / rate
        }
    }
}
