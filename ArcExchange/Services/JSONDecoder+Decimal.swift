import Foundation

extension JSONDecoder {
    static let dolarApp: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = DolarAppDateParser.date(from: raw) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognised date format: \(raw)"
            )
        }
        return decoder
    }()
}

enum DolarAppDateParser {
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatterNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func date(from raw: String) -> Date? {
        let normalised = normalise(raw)
        if let date = isoFormatter.date(from: normalised) {
            return date
        }
        return isoFormatterNoFraction.date(from: normalised)
    }

    private static func normalise(_ raw: String) -> String {
        var value = raw
        if !value.contains("Z") && !value.contains("+") && !hasNegativeOffset(value) {
            value += "Z"
        }
        guard let dot = value.firstIndex(of: ".") else { return value }
        let afterDot = value.index(after: dot)
        guard afterDot < value.endIndex else { return value }

        let suffixStart = value[afterDot...].firstIndex { !$0.isNumber } ?? value.endIndex
        let fraction = value[afterDot..<suffixStart]
        let suffix = value[suffixStart...]

        let truncated = fraction.prefix(3)
        return String(value[..<afterDot]) + truncated + suffix
    }

    private static func hasNegativeOffset(_ raw: String) -> Bool {
        guard raw.count > 11 else { return false }
        let tail = raw.dropFirst(11)
        return tail.contains("-")
    }
}

extension KeyedDecodingContainer {
    func decodeDecimalString(forKey key: Key) throws -> Decimal {
        let raw = try decode(String.self, forKey: key)
        guard let value = Decimal(string: raw, locale: Locale(identifier: "en_US_POSIX")) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Cannot parse '\(raw)' as Decimal"
            )
        }
        return value
    }
}
