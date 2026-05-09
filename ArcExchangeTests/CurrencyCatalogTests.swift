import Foundation
import Testing
@testable import ArcExchange

struct CurrencyCatalogTests {

    @Test
    func returns_codes_from_service_when_call_succeeds() async throws {
        let service = MockRateService()
        await service.setCurrencyResult(.success(["MXN", "BRL", "PEN"]))

        let codes = await CurrencyCatalog.load(using: service)
        #expect(codes == ["MXN", "BRL", "PEN"])
    }

    @Test
    func falls_back_to_hardcoded_list_when_service_throws() async {
        let service = MockRateService()
        await service.setCurrencyResult(.failure(RateServiceError.http(503)))

        let codes = await CurrencyCatalog.load(using: service)
        #expect(codes == ["MXN", "ARS", "BRL", "COP", "EURc"])
    }

    @Test
    func falls_back_when_service_returns_empty_array() async {
        let service = MockRateService()
        await service.setCurrencyResult(.success([]))

        let codes = await CurrencyCatalog.load(using: service)
        #expect(codes == ["MXN", "ARS", "BRL", "COP", "EURc"])
    }

    @Test
    func fallback_excludes_usdc_even_if_present_in_response() async {
        let service = MockRateService()
        await service.setCurrencyResult(.success(["USDC", "MXN", "BRL"]))

        let codes = await CurrencyCatalog.load(using: service)
        #expect(codes.contains("USDC") == false)
        #expect(codes == ["MXN", "BRL"])
    }
}
