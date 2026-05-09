import Foundation

enum CurrencyConverter {
    static func convert(amount: Decimal, mid: Decimal, direction: ConversionDirection) -> Decimal {
        guard mid > 0 else { return 0 }
        switch direction {
        case .fromUSDc: return amount * mid
        case .toUSDc:   return amount / mid
        }
    }
}
