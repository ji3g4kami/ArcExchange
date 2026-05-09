import Foundation

enum CurrencyCatalog {
    static var fallbackCodes: [String] { Currency.fallbackCodes }

    static func load(using service: any RateService) async -> [String] {
        do {
            let raw = try await service.availableCurrencies()
            let filtered = raw.filter { $0.uppercased() != "USDC" }
            if filtered.isEmpty { return fallbackCodes }
            return filtered
        } catch {
            return fallbackCodes
        }
    }
}
