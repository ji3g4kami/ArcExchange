import Foundation
import Testing
@testable import ArcExchange

struct CurrencyConverterTests {

    private let bid = Decimal(string: "18.40697")!
    private let ask = Decimal(string: "18.4105")!

    @Test
    func from_usdc_multiplies_by_bid() {
        // User sells USDc; market buys at bid. Use the bid side.
        let result = CurrencyConverter.convert(amount: Decimal(10), bid: bid, ask: ask, direction: .fromUSDc)
        #expect(result == Decimal(10) * bid)
    }

    @Test
    func to_usdc_divides_by_ask() {
        // User buys USDc with foreign; market sells at ask. Use the ask side.
        let result = CurrencyConverter.convert(amount: Decimal(184), bid: bid, ask: ask, direction: .toUSDc)
        #expect(result == Decimal(184) / ask)
    }

    @Test
    func from_usdc_does_not_use_mid_when_spread_is_nonzero() {
        // Regression for the prior bug where the converter averaged the spread away.
        let result = CurrencyConverter.convert(amount: Decimal(10), bid: Decimal(18), ask: Decimal(20), direction: .fromUSDc)
        #expect(result == Decimal(180))  // 10 × bid, NOT 10 × 19 (mid)
    }

    @Test
    func to_usdc_does_not_use_mid_when_spread_is_nonzero() {
        let result = CurrencyConverter.convert(amount: Decimal(200), bid: Decimal(18), ask: Decimal(20), direction: .toUSDc)
        #expect(result == Decimal(10))   // 200 ÷ ask, NOT 200 ÷ 19 (mid)
    }

    @Test
    func round_trip_with_zero_spread_preserves_value_within_epsilon() {
        // With bid == ask there's no spread to lose; round-trip should be exact.
        let rate = Decimal(string: "18.4087350")!
        let original = Decimal(string: "10.5")!
        let foreign = CurrencyConverter.convert(amount: original, bid: rate, ask: rate, direction: .fromUSDc)
        let roundTrip = CurrencyConverter.convert(amount: foreign, bid: rate, ask: rate, direction: .toUSDc)

        var difference = roundTrip - original
        var positiveDifference = Decimal()
        if difference < 0 { difference = -difference }
        var dummy = difference
        NSDecimalRound(&positiveDifference, &dummy, 12, .plain)

        #expect(positiveDifference < Decimal(string: "0.000000001")!)
    }

    @Test
    func zero_amount_returns_zero_in_either_direction() {
        let from = CurrencyConverter.convert(amount: 0, bid: bid, ask: ask, direction: .fromUSDc)
        let to = CurrencyConverter.convert(amount: 0, bid: bid, ask: ask, direction: .toUSDc)
        #expect(from == 0)
        #expect(to == 0)
    }

    @Test
    func nonpositive_rate_returns_zero() {
        let from = CurrencyConverter.convert(amount: Decimal(10), bid: 0, ask: ask, direction: .fromUSDc)
        let to = CurrencyConverter.convert(amount: Decimal(10), bid: bid, ask: 0, direction: .toUSDc)
        #expect(from == 0)
        #expect(to == 0)
    }

    /// Probe for the trailing-zeros artefact seen on the MXN row at extreme inputs.
    /// `Decimal` carries a 128-bit (~38-digit) mantissa, so a 25-digit USDc amount
    /// multiplied by a 4-fraction-digit rate should be exactly representable.
    /// The exact math here cannot end in many zeros (no factor of 10 in any term),
    /// so a long trailing-zero run in the product string would indicate the
    /// product is being rounded inside `NSDecimalMultiply`.
    @Test
    func large_amount_conversion_does_not_lose_precision() {
        let amount = Decimal(string: "8888888888778888888888888")!
        let probe = Decimal(string: "17.1762")!
        let product = CurrencyConverter.convert(amount: amount, bid: probe, ask: probe, direction: .fromUSDc)
        let productString = "\(product)"

        let integerPart = productString.split(separator: ".").first.map(String.init) ?? productString
        let trailingZeros = integerPart.reversed().prefix { $0 == "0" }.count

        #expect(trailingZeros < 5, "Got \(trailingZeros) trailing zeros — Decimal precision likely exhausted")
    }

    /// Guard that the `AmountInput.maxIntegerDigits` cap is set low enough that
    /// the converted product is still exact — no trailing zeros in the integer
    /// part and the fractional digits of the rate survive in the result.
    @Test
    func large_amount_at_input_cap_keeps_precision() {
        let digits = String(repeating: "9", count: AmountInput.maxIntegerDigits)
        let amount = Decimal(string: digits)!
        let probe = Decimal(string: "17.1762")!
        let product = CurrencyConverter.convert(amount: amount, bid: probe, ask: probe, direction: .fromUSDc)
        let productString = "\(product)"

        let parts = productString.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let integerPart = String(parts[0])
        let fractionalPart = parts.count > 1 ? String(parts[1]) : ""
        let trailingZeros = integerPart.reversed().prefix { $0 == "0" }.count

        #expect(trailingZeros == 0, "Got \(trailingZeros) trailing zeros — cap too high for Decimal precision")
        #expect(!fractionalPart.isEmpty, "Fractional digits dropped — cap too high for Decimal precision")
    }
}
