import Foundation

nonisolated struct Currency: Sendable, Equatable, Hashable, Identifiable {
    let code: String
    let flagAssetName: String?

    var id: String { code }

    var fractionDigitLimit: Int {
        code == "USDc" ? 6 : 2
    }

    // Canonical code expected by the API. `code` is the user-facing display
    // string (e.g. "EURc"); the API expects the ISO-style uppercase form
    // ("EURC"). For currencies whose display already matches the canonical
    // form this is a no-op.
    var apiCode: String { code.uppercased() }
}

extension Currency {
    nonisolated static let usdc = Currency(code: "USDc", flagAssetName: "flag_USDC")

    nonisolated static let knownByCode: [String: Currency] = [
        "USDC": .usdc,
        "MXN":  Currency(code: "MXN",  flagAssetName: "flag_MXN"),
        "ARS":  Currency(code: "ARS",  flagAssetName: "flag_ARS"),
        "BRL":  Currency(code: "BRL",  flagAssetName: "flag_BRL"),
        "COP":  Currency(code: "COP",  flagAssetName: "flag_COP"),
        "EURC": Currency(code: "EURc", flagAssetName: "flag_EURc")
    ]

    nonisolated static func resolve(_ code: String) -> Currency {
        knownByCode[code.uppercased()] ?? Currency(
            code: code.uppercased(),
            flagAssetName: nil
        )
    }

    nonisolated static let fallbackCodes: [String] = ["MXN", "ARS", "BRL", "COP", "EURc"]

    nonisolated static var fallback: [Currency] { fallbackCodes.map(Currency.resolve) }
}
