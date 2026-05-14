import Foundation
import Testing
@testable import ArcExchange

@MainActor
@Suite(.serialized)
struct ExchangeViewModelTests {

    private static func tickerMXN(ask: String = "20", bid: String = "18") -> Ticker {
        Ticker(
            ask: Decimal(string: ask)!,
            bid: Decimal(string: bid)!,
            book: "usdc_mxn"
        )
    }

    private static func tickerBRL(ask: String = "6", bid: String = "5") -> Ticker {
        Ticker(
            ask: Decimal(string: ask)!,
            bid: Decimal(string: bid)!,
            book: "usdc_brl"
        )
    }

    private static func tickerEUR(ask: String = "0.85", bid: String = "0.84") -> Ticker {
        Ticker(
            ask: Decimal(string: ask)!,
            bid: Decimal(string: bid)!,
            book: "usdc_eurc"
        )
    }

    private static let epsilon = Decimal(string: "0.000001")!

    private static func absoluteDifference(_ lhs: Decimal, _ rhs: Decimal) -> Decimal {
        let diff = lhs - rhs
        return diff < 0 ? -diff : diff
    }

    @Test
    func initial_state_is_idle_with_fallback_currencies_and_default_selection() async {
        let service = MockRateService()
        let viewModel = ExchangeViewModel(service: service)

        #expect(viewModel.state == .idle)
        #expect(viewModel.availableCurrencies.map(\.code) == ["MXN", "ARS", "BRL", "COP", "EURc"])
        #expect(viewModel.selectedCurrency.code == "MXN")
        #expect(viewModel.usdcAmount == nil)
        #expect(viewModel.foreignAmount == nil)
    }

    @Test
    func bootstrap_loads_tickers_and_currency_list() async {
        let service = MockRateService()
        await service.setCurrencyResult(.success(["MXN", "BRL"]))
        await service.setTickerResult(.success([Self.tickerMXN()]))

        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.rate?.currencyCode == "MXN")
        #expect(viewModel.availableCurrencies.map(\.code) == ["MXN", "BRL"])
        #expect(viewModel.lastUpdated != nil)
    }

    @Test
    func bootstrap_failure_keeps_fallback_currencies_and_sets_failed_state() async {
        let service = MockRateService()
        await service.setCurrencyResult(.failure(RateServiceError.http(503)))
        await service.setTickerResult(.failure(RateServiceError.transport("offline")))

        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()

        if case .failed = viewModel.state {} else {
            Issue.record("Expected failed state, got \(viewModel.state)")
        }
        #expect(viewModel.availableCurrencies.map(\.code) == ["MXN", "ARS", "BRL", "COP", "EURc"])
    }

    @Test
    func editing_usdc_recomputes_foreign_using_bid() async {
        let service = MockRateService()
        await service.setTickerResult(.success([Self.tickerMXN(ask: "20", bid: "18")]))
        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()

        viewModel.usdcAmount = Decimal(10)
        viewModel.userEditedUSDc()

        // User sells USDc → market buys at bid (18), not mid (19).
        let expected = Decimal(10) * Decimal(18)
        let actual = viewModel.foreignAmount ?? 0
        #expect(Self.absoluteDifference(actual, expected) < Self.epsilon)
        #expect(viewModel.activeEditor == .fromUSDc)
    }

    @Test
    func editing_foreign_recomputes_usdc_using_ask() async {
        let service = MockRateService()
        await service.setTickerResult(.success([Self.tickerMXN(ask: "20", bid: "18")]))
        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()

        viewModel.foreignAmount = Decimal(200)
        viewModel.userEditedForeign()

        // User buys USDc with foreign → market sells at ask (20), not mid (19).
        let expectedUsdc = Decimal(200) / Decimal(20)
        let actual = viewModel.usdcAmount ?? 0
        #expect(Self.absoluteDifference(actual, expectedUsdc) < Self.epsilon)
        #expect(viewModel.activeEditor == .toUSDc)
    }

    @Test
    func clearing_input_clears_other_field() async {
        let service = MockRateService()
        await service.setTickerResult(.success([Self.tickerMXN()]))
        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()

        viewModel.usdcAmount = Decimal(10)
        viewModel.userEditedUSDc()
        #expect(viewModel.foreignAmount != nil)

        viewModel.usdcAmount = nil
        viewModel.userEditedUSDc()
        #expect(viewModel.foreignAmount == nil)
    }

    @Test
    func selecting_eur_sends_uppercase_EURC_to_api() async {
        let service = MockRateService()
        await service.setCurrencyResult(.success(["MXN", "EURc"]))
        await service.setTickerResult(.success([Self.tickerMXN()]))
        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()

        await service.setTickerResult(.success([Self.tickerEUR()]))
        await viewModel.selectCurrency(Currency.resolve("EURc"))

        let calls = await service.tickerCalls
        #expect(calls.last == ["EURC"], "API should receive uppercase EURC, not display string EURc")
    }

    @Test
    func bootstrap_with_eur_selected_sends_uppercase_to_api() async {
        let service = MockRateService()
        await service.setTickerResult(.success([Self.tickerEUR()]))
        let viewModel = ExchangeViewModel(service: service)
        // Force selection to EURc before bootstrap to exercise the bootstrap path.
        await viewModel.selectCurrency(Currency.resolve("EURc"))
        let bootstrapStart = await service.tickerCalls.count

        await viewModel.bootstrap()

        let calls = await service.tickerCalls
        let bootstrapCall = calls[bootstrapStart]
        #expect(bootstrapCall == ["EURC"])
    }

    @Test
    func selecting_currency_triggers_refresh_for_that_currency() async {
        let service = MockRateService()
        await service.setCurrencyResult(.success(["MXN", "BRL"]))
        await service.setTickerResult(.success([Self.tickerMXN()]))
        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()

        await service.setTickerResult(.success([Self.tickerBRL()]))
        let brl = Currency.resolve("BRL")
        await viewModel.selectCurrency(brl)

        #expect(viewModel.selectedCurrency.code == "BRL")
        #expect(viewModel.rate?.currencyCode == "BRL")
        let calls = await service.tickerCalls
        #expect(calls.last == ["BRL"])
    }

    @Test
    func error_during_refresh_preserves_previous_rate() async {
        let service = MockRateService()
        await service.setTickerResult(.success([Self.tickerMXN()]))
        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()
        let originalRate = viewModel.rate

        await service.setTickerResult(.failure(RateServiceError.transport("nope")))
        await viewModel.refresh()

        #expect(viewModel.rate == originalRate)
        if case .failed = viewModel.state {} else {
            Issue.record("Expected failed state, got \(viewModel.state)")
        }
    }

    @Test
    func selecting_currency_clears_stale_rate_when_refresh_fails() async {
        let service = MockRateService()
        await service.setCurrencyResult(.success(["MXN", "BRL"]))
        await service.setTickerResult(.success([Self.tickerMXN()]))
        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()
        #expect(viewModel.rate?.currencyCode == "MXN")

        await service.setTickerResult(.failure(RateServiceError.transport("offline")))
        await viewModel.selectCurrency(Currency.resolve("BRL"))

        #expect(viewModel.rate == nil)
        #expect(viewModel.lastUpdated == nil)
        #expect(viewModel.formattedRate == nil)
        if case .failed = viewModel.state {} else {
            Issue.record("Expected failed state, got \(viewModel.state)")
        }
    }

    @Test
    func failed_currency_switch_clears_typed_amounts() async {
        let service = MockRateService()
        await service.setCurrencyResult(.success(["MXN", "BRL"]))
        await service.setTickerResult(.success([Self.tickerMXN()]))
        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()

        viewModel.usdcAmount = Decimal(10)
        viewModel.userEditedUSDc()
        #expect(viewModel.usdcAmount != nil)
        #expect(viewModel.foreignAmount != nil)

        await service.setTickerResult(.failure(RateServiceError.http(500)))
        await viewModel.selectCurrency(Currency.resolve("BRL"))

        #expect(viewModel.rate == nil)
        #expect(viewModel.usdcAmount == nil)
        #expect(viewModel.foreignAmount == nil)
    }

    @Test
    func recompute_does_nothing_after_failed_currency_switch() async {
        let service = MockRateService()
        await service.setCurrencyResult(.success(["MXN", "BRL"]))
        await service.setTickerResult(.success([Self.tickerMXN()]))
        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()

        await service.setTickerResult(.failure(RateServiceError.transport("offline")))
        await viewModel.selectCurrency(Currency.resolve("BRL"))

        viewModel.usdcAmount = Decimal(10)
        viewModel.userEditedUSDc()
        #expect(viewModel.foreignAmount == nil)
    }

    @Test
    func formatted_rate_is_nil_before_load() async {
        let service = MockRateService()
        let viewModel = ExchangeViewModel(service: service)
        #expect(viewModel.formattedRate == nil)
    }

    @Test
    func formatted_rate_renders_one_usdc_to_selected_currency() async {
        let service = MockRateService()
        await service.setTickerResult(.success([Self.tickerMXN(ask: "20", bid: "18")]))
        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()

        let formatted = viewModel.formattedRate ?? ""
        #expect(formatted.hasPrefix("1 USDc = "))
        #expect(formatted.hasSuffix(" MXN"))
    }

    @Test
    func formatted_rate_updates_after_currency_change() async {
        let service = MockRateService()
        await service.setCurrencyResult(.success(["MXN", "BRL"]))
        await service.setTickerResult(.success([Self.tickerMXN()]))
        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()

        await service.setTickerResult(.success([Self.tickerBRL()]))
        await viewModel.selectCurrency(Currency.resolve("BRL"))

        let formatted = viewModel.formattedRate ?? ""
        #expect(formatted.hasSuffix(" BRL"))
    }

    @Test
    func swap_flips_visual_layout_and_active_editor_keeping_inputs_attached_to_their_currency() async {
        let service = MockRateService()
        await service.setTickerResult(.success([Self.tickerMXN()]))
        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()

        viewModel.usdcAmount = Decimal(10)
        viewModel.userEditedUSDc()
        let usdcBefore = viewModel.usdcAmount
        let foreignBefore = viewModel.foreignAmount
        #expect(viewModel.usdcOnTop)
        #expect(viewModel.activeEditor == .fromUSDc)

        viewModel.swap()

        #expect(viewModel.usdcOnTop == false)
        #expect(viewModel.activeEditor == .toUSDc)
        #expect(viewModel.usdcAmount == usdcBefore)
        #expect(viewModel.foreignAmount == foreignBefore)

        viewModel.swap()
        #expect(viewModel.usdcOnTop == true)
        #expect(viewModel.activeEditor == .fromUSDc)
    }
}
