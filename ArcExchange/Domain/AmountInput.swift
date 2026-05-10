import Foundation

enum AmountInput {

    static func sanitize(_ raw: String) -> String {
        var seenDot = false
        var out = ""
        out.reserveCapacity(raw.count)
        for char in raw {
            if char.isASCII, char.isNumber {
                out.append(char)
            } else if char == "." && !seenDot {
                out.append(char)
                seenDot = true
            }
        }
        return out
    }

    static func parse(_ text: String) -> Decimal? {
        if text.isEmpty || text == "." { return nil }
        let normalised = text.hasPrefix(".") ? "0" + text : text
        return Decimal(string: normalised, locale: Locale(identifier: "en_US_POSIX"))
    }

    static func displayGrouped(forSanitized text: String) -> String {
        if text.isEmpty { return "" }
        if let dotIdx = text.firstIndex(of: ".") {
            let intPart = String(text[..<dotIdx])
            let fracPart = String(text[text.index(after: dotIdx)...])
            return groupDigits(intPart) + "." + fracPart
        }
        return groupDigits(text)
    }

    static func displayGrouped(forAmount amount: Decimal?, fractionDigitLimit: Int) -> String {
        guard var value = amount else { return "" }
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, fractionDigitLimit, .plain)
        return displayGrouped(forSanitized: "\(rounded)")
    }

    static func limitFraction(_ text: String, max: Int) -> String {
        guard let dotIdx = text.firstIndex(of: ".") else { return text }
        let afterDot = text.index(after: dotIdx)
        let fractionLen = text.distance(from: afterDot, to: text.endIndex)
        if fractionLen <= max { return text }
        let clip = text.index(afterDot, offsetBy: max)
        return String(text[..<clip])
    }

    static func logicalCursor(in text: String) -> Int {
        var count = 0
        for char in text {
            if (char.isASCII && char.isNumber) || char == "." {
                count += 1
            }
        }
        return count
    }

    static func displayCursorOffset(forFormatted text: String, logicalCursor: Int) -> Int {
        var offset = 0
        var counted = 0
        for char in text {
            if counted >= logicalCursor { break }
            offset += 1
            if (char.isASCII && char.isNumber) || char == "." {
                counted += 1
            }
        }
        return offset
    }

    private static func groupDigits(_ digits: String) -> String {
        guard digits.count > 3 else { return digits }
        var result = ""
        var counter = 0
        for char in digits.reversed() {
            if counter > 0 && counter % 3 == 0 {
                result.insert(",", at: result.startIndex)
            }
            result.insert(char, at: result.startIndex)
            counter += 1
        }
        return result
    }
}
