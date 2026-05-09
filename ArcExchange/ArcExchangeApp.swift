import SwiftUI

@main
struct ArcExchangeApp: App {
    @State private var viewModel: ExchangeViewModel

    init() {
        let args = ProcessInfo.processInfo.arguments
        func isFlagEnabled(_ key: String) -> Bool {
            guard let index = args.firstIndex(of: key), index + 1 < args.count else { return false }
            return args[index + 1] == "1"
        }
        let service: any RateService
        if isFlagEnabled("-UITestStubFailure") {
            service = StubFailingService()
        } else if isFlagEnabled("-UITestStubSuccess") {
            service = StubSuccessService()
        } else {
            service = LiveRateService()
        }
        _viewModel = State(initialValue: ExchangeViewModel(service: service))
    }

    var body: some Scene {
        WindowGroup {
            ExchangeScreen(viewModel: viewModel)
        }
    }
}

private struct StubFailingService: RateService {
    func tickers(for currencyCodes: [String]) async throws -> [Ticker] {
        throw RateServiceError.transport("Stub: forced failure")
    }
    func availableCurrencies() async throws -> [String] {
        throw RateServiceError.transport("Stub: forced failure")
    }
}

private struct StubSuccessService: RateService {
    func tickers(for currencyCodes: [String]) async throws -> [Ticker] {
        currencyCodes.map { code in
            Ticker(
                ask: Decimal(string: "20.5")!,
                bid: Decimal(string: "19.5")!,
                book: "usdc_\(code.lowercased())",
                date: Date()
            )
        }
    }
    func availableCurrencies() async throws -> [String] {
        ["MXN", "ARS", "BRL", "COP", "EURc"]
    }
}
