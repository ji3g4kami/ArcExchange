import Foundation

struct LiveRateService: RateService {
    let session: URLSession
    let baseURL: URL

    init(
        session: URLSession = .shared,
        baseURL: URL = URL(string: "https://api.dolarapp.dev/v1")!
    ) {
        self.session = session
        self.baseURL = baseURL
    }

    func tickers(for currencyCodes: [String]) async throws -> [Ticker] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("tickers"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "currencies", value: currencyCodes.joined(separator: ","))
        ]
        guard let url = components?.url else { throw RateServiceError.invalidURL }
        let data = try await fetchData(url: url)
        do {
            return try JSONDecoder.dolarApp().decode([Ticker].self, from: data)
        } catch {
            throw RateServiceError.decoding(String(describing: error))
        }
    }

    func availableCurrencies() async throws -> [String] {
        let url = baseURL.appendingPathComponent("tickers-currencies")
        let data = try await fetchData(url: url)
        do {
            return try JSONDecoder().decode([String].self, from: data)
        } catch {
            throw RateServiceError.decoding(String(describing: error))
        }
    }

    private func fetchData(url: URL) async throws -> Data {
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                throw RateServiceError.transport("Non-HTTP response")
            }
            guard (200..<300).contains(http.statusCode) else {
                throw RateServiceError.http(http.statusCode)
            }
            return data
        } catch let error as RateServiceError {
            throw error
        } catch {
            throw RateServiceError.transport(String(describing: error))
        }
    }
}
