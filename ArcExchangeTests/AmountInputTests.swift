import Foundation
import Testing
@testable import ArcExchange

struct AmountInputTests {

    // MARK: - sanitize

    @Test
    func sanitize_keeps_ascii_digits() {
        #expect(AmountInput.sanitize("123") == "123")
        #expect(AmountInput.sanitize("0") == "0")
    }

    @Test
    func sanitize_keeps_first_dot_drops_subsequent() {
        #expect(AmountInput.sanitize("1.23") == "1.23")
        #expect(AmountInput.sanitize("1.2.3.4") == "1.234")
        #expect(AmountInput.sanitize(".5") == ".5")
    }

    @Test
    func sanitize_strips_letters_and_punctuation() {
        #expect(AmountInput.sanitize("abc123") == "123")
        #expect(AmountInput.sanitize("1,234.56") == "1234.56")
        #expect(AmountInput.sanitize("12 34") == "1234")
        #expect(AmountInput.sanitize("-15") == "15")
        #expect(AmountInput.sanitize("12$34") == "1234")
    }

    @Test
    func sanitize_strips_non_ascii_digits() {
        #expect(AmountInput.sanitize("١٢٣") == "")
        #expect(AmountInput.sanitize("123४") == "123")
    }

    @Test
    func sanitize_empty_stays_empty() {
        #expect(AmountInput.sanitize("") == "")
    }

    // MARK: - parse

    @Test
    func parse_empty_or_lone_dot_is_nil() {
        #expect(AmountInput.parse("") == nil)
        #expect(AmountInput.parse(".") == nil)
    }

    @Test
    func parse_valid_decimal() {
        #expect(AmountInput.parse("123") == Decimal(123))
        #expect(AmountInput.parse("12.34") == Decimal(string: "12.34")!)
        #expect(AmountInput.parse("0.5") == Decimal(string: "0.5")!)
    }

    @Test
    func parse_normalises_leading_dot() {
        #expect(AmountInput.parse(".5") == Decimal(string: "0.5")!)
    }

    // MARK: - displayGrouped(forSanitized:)

    @Test
    func displayGrouped_sanitized_empty() {
        #expect(AmountInput.displayGrouped(forSanitized: "") == "")
    }

    @Test
    func displayGrouped_sanitized_under_thousand() {
        #expect(AmountInput.displayGrouped(forSanitized: "0") == "0")
        #expect(AmountInput.displayGrouped(forSanitized: "999") == "999")
    }

    @Test
    func displayGrouped_sanitized_at_and_above_thousand() {
        #expect(AmountInput.displayGrouped(forSanitized: "1000") == "1,000")
        #expect(AmountInput.displayGrouped(forSanitized: "12345") == "12,345")
        #expect(AmountInput.displayGrouped(forSanitized: "1234567") == "1,234,567")
    }

    @Test
    func displayGrouped_sanitized_with_decimal() {
        #expect(AmountInput.displayGrouped(forSanitized: "12345.6789") == "12,345.6789")
        #expect(AmountInput.displayGrouped(forSanitized: "0.5") == "0.5")
    }

    @Test
    func displayGrouped_sanitized_preserves_trailing_dot() {
        #expect(AmountInput.displayGrouped(forSanitized: "1234.") == "1,234.")
    }

    @Test
    func displayGrouped_sanitized_preserves_leading_dot() {
        #expect(AmountInput.displayGrouped(forSanitized: ".5") == ".5")
    }

    // MARK: - displayGrouped(forAmount:fractionDigitLimit:)

    @Test
    func displayGrouped_amount_nil_is_empty() {
        #expect(AmountInput.displayGrouped(forAmount: nil, fractionDigitLimit: 2) == "")
    }

    @Test
    func displayGrouped_amount_rounds_to_limit() {
        let value = Decimal(string: "12345.678")!
        #expect(AmountInput.displayGrouped(forAmount: value, fractionDigitLimit: 2) == "12,345.68")
    }

    @Test
    func displayGrouped_amount_no_unnecessary_zeros() {
        #expect(AmountInput.displayGrouped(forAmount: Decimal(1000), fractionDigitLimit: 2) == "1,000")
        #expect(AmountInput.displayGrouped(forAmount: Decimal(string: "1.5")!, fractionDigitLimit: 6) == "1.5")
    }

    @Test
    func displayGrouped_amount_handles_large_numbers() {
        let value = Decimal(string: "227142.5")!
        #expect(AmountInput.displayGrouped(forAmount: value, fractionDigitLimit: 2) == "227,142.5")
    }

    // MARK: - limitFraction

    @Test
    func limitFraction_no_dot_unchanged() {
        #expect(AmountInput.limitFraction("12345", max: 2) == "12345")
    }

    @Test
    func limitFraction_under_or_at_limit_unchanged() {
        #expect(AmountInput.limitFraction("1.2", max: 6) == "1.2")
        #expect(AmountInput.limitFraction("1.23", max: 2) == "1.23")
    }

    @Test
    func limitFraction_over_limit_clipped() {
        #expect(AmountInput.limitFraction("1.234567", max: 2) == "1.23")
        #expect(AmountInput.limitFraction("1.999", max: 0) == "1.")
    }

    @Test
    func limitFraction_trailing_dot_unchanged() {
        #expect(AmountInput.limitFraction("123.", max: 2) == "123.")
    }

    // MARK: - logicalCursor / displayCursorOffset

    @Test
    func logicalCursor_counts_digits_and_dot() {
        #expect(AmountInput.logicalCursor(in: "") == 0)
        #expect(AmountInput.logicalCursor(in: "12") == 2)
        #expect(AmountInput.logicalCursor(in: "1,2") == 2)
        #expect(AmountInput.logicalCursor(in: "12,345") == 5)
        #expect(AmountInput.logicalCursor(in: "12,345.6") == 7)
        #expect(AmountInput.logicalCursor(in: "abc12") == 2)
    }

    @Test
    func displayCursorOffset_at_start() {
        #expect(AmountInput.displayCursorOffset(forFormatted: "1,234", logicalCursor: 0) == 0)
    }

    @Test
    func displayCursorOffset_at_end() {
        #expect(AmountInput.displayCursorOffset(forFormatted: "1,234", logicalCursor: 4) == 5)
    }

    @Test
    func displayCursorOffset_middle_after_digit() {
        // "1,234" — after 2nd digit "12" → between '2' and '3' → offset 3
        #expect(AmountInput.displayCursorOffset(forFormatted: "1,234", logicalCursor: 2) == 3)
        // After 3rd digit "123" → between '3' and '4' → offset 4
        #expect(AmountInput.displayCursorOffset(forFormatted: "1,234", logicalCursor: 3) == 4)
    }

    @Test
    func displayCursorOffset_with_decimal() {
        // "1,234.56" — after 5 digit/dot chars "1234." → between '.' and '5' → offset 6
        #expect(AmountInput.displayCursorOffset(forFormatted: "1,234.56", logicalCursor: 5) == 6)
        // After 6 → after '5' → offset 7
        #expect(AmountInput.displayCursorOffset(forFormatted: "1,234.56", logicalCursor: 6) == 7)
    }

    @Test
    func displayCursorOffset_clamps_at_text_end() {
        // logicalCursor larger than digit count → end of formatted text
        #expect(AmountInput.displayCursorOffset(forFormatted: "1,234", logicalCursor: 99) == 5)
    }
}
