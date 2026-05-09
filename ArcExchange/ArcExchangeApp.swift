import SwiftUI

@main
struct ArcExchangeApp: App {
    @State private var viewModel: ExchangeViewModel

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let service: any RateService
        if arguments.contains("-UITestStubFailure") && nextArgument(after: "-UITestStubFailure", in: arguments) == "1" {
            service = StubFailingService()
        } else if arguments.contains("-UITestStubSuccess") && nextArgument(after: "-UITestStubSuccess", in: arguments) == "1" {
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

private func nextArgument(after key: String, in arguments: [String]) -> String? {
    guard let index = arguments.firstIndex(of: key), index + 1 < arguments.count else { return nil }
    return arguments[index + 1]
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
        ["MXN", "ARS", "BRL", "COP"]
    }
}
