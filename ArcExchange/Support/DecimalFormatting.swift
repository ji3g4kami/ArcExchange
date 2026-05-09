import Foundation

enum DecimalFormatting {
    static let displayFractionDigits = 6

    static func parse(_ raw: String, locale: Locale = .current) -> Decimal? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let formatter = numberFormatter(for: locale)
        if let number = formatter.number(from: trimmed) {
            return number.decimalValue
        }
        if let value = Decimal(string: trimmed, locale: locale) {
            return value
        }
        if let value = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")) {
            return value
        }
        return nil
    }

    static func display(_ value: Decimal, locale: Locale = .current) -> String {
        if value == 0 { return "" }
        let formatter = displayFormatter(for: locale)
        return formatter.string(from: value as NSDecimalNumber) ?? ""
    }

    private static func numberFormatter(for locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.generatesDecimalNumbers = true
        formatter.usesGroupingSeparator = false
        return formatter
    }

    private static func displayFormatter(for locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.generatesDecimalNumbers = true
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = displayFractionDigits
        formatter.usesGroupingSeparator = true
        return formatter
    }
}
