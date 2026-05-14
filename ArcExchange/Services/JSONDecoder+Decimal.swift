import Foundation

extension JSONDecoder {
    static let dolarApp: JSONDecoder = JSONDecoder()
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
