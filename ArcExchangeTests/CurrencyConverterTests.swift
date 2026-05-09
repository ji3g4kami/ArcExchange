import Foundation
import Testing
@testable import ArcExchange

struct CurrencyConverterTests {

    private let mid = Decimal(string: "18.4087350")!

    @Test
    func from_usdc_multiplies_by_mid() {
        let result = CurrencyConverter.convert(amount: Decimal(10), mid: mid, direction: .fromUSDc)
        #expect(result == Decimal(10) * mid)
    }

    @Test
    func to_usdc_divides_by_mid() {
        let result = CurrencyConverter.convert(amount: Decimal(184), mid: mid, direction: .toUSDc)
        #expect(result == Decimal(184) / mid)
    }

    @Test
    func round_trip_usdc_to_foreign_to_usdc_preserves_value_within_epsilon() {
        let original = Decimal(string: "10.5")!
        let foreign = CurrencyConverter.convert(amount: original, mid: mid, direction: .fromUSDc)
        let roundTrip = CurrencyConverter.convert(amount: foreign, mid: mid, direction: .toUSDc)

        var difference = roundTrip - original
        var positiveDifference = Decimal()
        if difference < 0 { difference = -difference }
        var dummy = difference
        NSDecimalRound(&positiveDifference, &dummy, 12, .plain)

        #expect(positiveDifference < Decimal(string: "0.000000001")!)
    }

    @Test
    func zero_amount_returns_zero_in_either_direction() {
        let from = CurrencyConverter.convert(amount: 0, mid: mid, direction: .fromUSDc)
        let to = CurrencyConverter.convert(amount: 0, mid: mid, direction: .toUSDc)
        #expect(from == 0)
        #expect(to == 0)
    }
}
