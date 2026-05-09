import Foundation
import Testing
@testable import ArcExchange

@Suite(.serialized)
struct LiveRateServiceTests {

    @Test
    func tickers_url_encodes_currencies_query_as_comma_separated() async throws {
        StubURLProtocol.reset()
        let session = StubURLProtocol.install()

        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, TickersFixture.twoTickersData)
        }

        let service = LiveRateService(session: session)
        _ = try await service.tickers(for: ["MXN", "ARS"])

        let request = try #require(StubURLProtocol.lastRequest)
        let url = try #require(request.url)
        #expect(url.host == "api.dolarapp.dev")
        #expect(url.path == "/v1/tickers")
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let currenciesItem = try #require(components.queryItems?.first { $0.name == "currencies" })
        #expect(currenciesItem.value == "MXN,ARS")
    }

    @Test
    func tickers_decodes_response_into_models() async throws {
        StubURLProtocol.reset()
        let session = StubURLProtocol.install()

        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, TickersFixture.twoTickersData)
        }

        let service = LiveRateService(session: session)
        let tickers = try await service.tickers(for: ["MXN", "ARS"])
        #expect(tickers.count == 2)
        #expect(tickers[0].book == "usdc_mxn")
    }

    @Test
    func tickers_non_200_status_maps_to_http_error() async {
        StubURLProtocol.reset()
        let session = StubURLProtocol.install()

        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let service = LiveRateService(session: session)
        await #expect(throws: RateServiceError.http(503)) {
            _ = try await service.tickers(for: ["MXN"])
        }
    }

    @Test
    func tickers_decoding_failure_maps_to_decoding_error() async {
        StubURLProtocol.reset()
        let session = StubURLProtocol.install()

        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("not json at all".utf8))
        }

        let service = LiveRateService(session: session)
        do {
            _ = try await service.tickers(for: ["MXN"])
            Issue.record("Expected decoding error")
        } catch let error as RateServiceError {
            guard case .decoding = error else {
                Issue.record("Expected .decoding, got \(error)")
                return
            }
        } catch {
            Issue.record("Expected RateServiceError, got \(error)")
        }
    }

    @Test
    func availableCurrencies_decodes_string_array() async throws {
        StubURLProtocol.reset()
        let session = StubURLProtocol.install()

        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data(#"["MXN","ARS","BRL","COP"]"#.utf8))
        }

        let service = LiveRateService(session: session)
        let codes = try await service.availableCurrencies()
        #expect(codes == ["MXN", "ARS", "BRL", "COP"])
    }

    @Test
    func availableCurrencies_endpoint_path_is_tickers_currencies() async throws {
        StubURLProtocol.reset()
        let session = StubURLProtocol.install()

        StubURLProtocol.handler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("[]".utf8))
        }

        let service = LiveRateService(session: session)
        _ = try await service.availableCurrencies()
        let request = try #require(StubURLProtocol.lastRequest)
        #expect(request.url?.path == "/v1/tickers-currencies")
    }
}
