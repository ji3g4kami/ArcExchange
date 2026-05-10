import Foundation

nonisolated struct LiveRateService: RateService {
    let session: URLSession
    let baseURL: URL
    let maxResponseBytes: Int

    // 15 s vs the 60 s system default: the rate JSON is tiny, so a slow peer
    // holding the connection longer than that is a stuck request, not a slow one.
    private static let defaultRequestTimeout: TimeInterval = 15

    // 1 MB vs the ~10 KB the endpoint actually returns: bounds memory growth
    // from a misbehaving or compromised endpoint while leaving headroom.
    private static let defaultMaxResponseBytes = 1_000_000

    private static let defaultSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = defaultRequestTimeout
        config.timeoutIntervalForResource = defaultRequestTimeout * 2
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    init(
        session: URLSession = LiveRateService.defaultSession,
        baseURL: URL = URL(string: "https://api.dolarapp.dev/v1")!,
        maxResponseBytes: Int = LiveRateService.defaultMaxResponseBytes
    ) {
        self.session = session
        self.baseURL = baseURL
        self.maxResponseBytes = maxResponseBytes
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
            return try JSONDecoder.dolarApp.decode([Ticker].self, from: data)
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
            let (bytes, response) = try await session.bytes(from: url)
            guard let http = response as? HTTPURLResponse else {
                throw RateServiceError.transport("Non-HTTP response")
            }
            guard (200..<300).contains(http.statusCode) else {
                throw RateServiceError.http(http.statusCode)
            }
            if let lengthHeader = http.value(forHTTPHeaderField: "Content-Length"),
               let length = Int(lengthHeader),
               length > maxResponseBytes {
                throw RateServiceError.transport("Response too large")
            }
            var data = Data()
            data.reserveCapacity(min(maxResponseBytes, 16_384))
            for try await byte in bytes {
                data.append(byte)
                if data.count > maxResponseBytes {
                    throw RateServiceError.transport("Response too large")
                }
            }
            return data
        } catch let error as RateServiceError {
            throw error
        } catch {
            throw RateServiceError.transport(String(describing: error))
        }
    }
}
