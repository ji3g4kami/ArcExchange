import Foundation

struct Currency: Sendable, Equatable, Hashable, Identifiable {
    let code: String
    let flagAssetName: String?

    var id: String { code }

    var fractionDigitLimit: Int {
        code == "USDc" ? 6 : 2
    }
}

extension Currency {
    static let usdc = Currency(code: "USDc", flagAssetName: "flag_USDC")

    static let knownByCode: [String: Currency] = [
        "USDC": .usdc,
        "MXN":  Currency(code: "MXN",  flagAssetName: "flag_MXN"),
        "ARS":  Currency(code: "ARS",  flagAssetName: "flag_ARS"),
        "BRL":  Currency(code: "BRL",  flagAssetName: "flag_BRL"),
        "COP":  Currency(code: "COP",  flagAssetName: "flag_COP"),
        "EURC": Currency(code: "EURc", flagAssetName: "flag_EURc")
    ]

    static func resolve(_ code: String) -> Currency {
        knownByCode[code.uppercased()] ?? Currency(
            code: code.uppercased(),
            flagAssetName: nil
        )
    }

    static let fallbackCodes: [String] = ["MXN", "ARS", "BRL", "COP", "EURc"]

    static var fallback: [Currency] { fallbackCodes.map(Currency.resolve) }
}
