import Foundation

struct Currency: Sendable, Equatable, Hashable, Identifiable {
    let code: String
    let flag: String
    let flagAssetName: String?

    var id: String { code }

    var fractionDigitLimit: Int {
        code == "USDC" ? 6 : 2
    }
}

extension Currency {
    static let usdc = Currency(code: "USDC", flag: "🪙", flagAssetName: "flag_USDC")

    static let knownByCode: [String: Currency] = [
        "USDC": .usdc,
        "MXN":  Currency(code: "MXN",  flag: "🇲🇽", flagAssetName: "flag_MXN"),
        "ARS":  Currency(code: "ARS",  flag: "🇦🇷", flagAssetName: "flag_ARS"),
        "BRL":  Currency(code: "BRL",  flag: "🇧🇷", flagAssetName: "flag_BRL"),
        "COP":  Currency(code: "COP",  flag: "🇨🇴", flagAssetName: "flag_COP"),
        "EURC": Currency(code: "EURc", flag: "🇪🇺", flagAssetName: "flag_EURc")
    ]

    static func resolve(_ code: String) -> Currency {
        knownByCode[code.uppercased()] ?? Currency(
            code: code.uppercased(),
            flag: "🌐",
            flagAssetName: nil
        )
    }

    static let fallbackCodes: [String] = ["MXN", "ARS", "BRL", "COP", "EURc"]

    static var fallback: [Currency] { fallbackCodes.map(Currency.resolve) }
}
