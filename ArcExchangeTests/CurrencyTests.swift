import Foundation
import Testing
@testable import ArcExchange

struct CurrencyTests {

    @Test
    func eurc_resolves_to_display_code_with_lowercase_c() {
        let eur = Currency.resolve("EURc")
        #expect(eur.code == "EURc")
    }

    @Test
    func eurc_api_code_is_uppercase_EURC() {
        let eur = Currency.resolve("EURc")
        #expect(eur.apiCode == "EURC")
    }

    @Test
    func mxn_api_code_matches_display() {
        let mxn = Currency.resolve("MXN")
        #expect(mxn.apiCode == "MXN")
    }

    @Test
    func usdc_api_code_is_uppercase_USDC() {
        #expect(Currency.usdc.apiCode == "USDC")
    }

    @Test
    func resolve_uppercases_unknown_input_for_lookup() {
        // Defensive: resolve("eurc") and resolve("EURC") both find the known mapping.
        #expect(Currency.resolve("eurc").apiCode == "EURC")
        #expect(Currency.resolve("EURC").apiCode == "EURC")
    }
}
