import Foundation

struct Currency: Sendable, Equatable, Hashable, Identifiable {
    let code: String
    let displayName: String
    let flag: String

    var id: String { code }
}

extension Currency {
    static let usdc = Currency(code: "USDC", displayName: "USD Coin", flag: "🪙")

    static let knownByCode: [String: Currency] = [
        "USDC": .usdc,
        "MXN":  Currency(code: "MXN",  displayName: "Mexican Peso",       flag: "🇲🇽"),
        "ARS":  Currency(code: "ARS",  displayName: "Argentine Peso",     flag: "🇦🇷"),
        "BRL":  Currency(code: "BRL",  displayName: "Brazilian Real",     flag: "🇧🇷"),
        "COP":  Currency(code: "COP",  displayName: "Colombian Peso",     flag: "🇨🇴"),
        "PEN":  Currency(code: "PEN",  displayName: "Peruvian Sol",       flag: "🇵🇪"),
        "CLP":  Currency(code: "CLP",  displayName: "Chilean Peso",       flag: "🇨🇱"),
        "UYU":  Currency(code: "UYU",  displayName: "Uruguayan Peso",     flag: "🇺🇾"),
        "EUR":  Currency(code: "EUR",  displayName: "Euro",               flag: "🇪🇺"),
        "GBP":  Currency(code: "GBP",  displayName: "British Pound",      flag: "🇬🇧")
    ]

    static func resolve(_ code: String) -> Currency {
        knownByCode[code.uppercased()] ?? Currency(
            code: code.uppercased(),
            displayName: code.uppercased(),
            flag: "🌐"
        )
    }

    static let fallbackCodes: [String] = ["MXN", "ARS", "BRL", "COP"]

    static var fallback: [Currency] { fallbackCodes.map(Currency.resolve) }
}
