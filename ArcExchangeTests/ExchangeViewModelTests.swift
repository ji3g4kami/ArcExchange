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
            book: "usdc_mxn",
            date: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    private static func tickerBRL(ask: String = "6", bid: String = "5") -> Ticker {
        Ticker(
            ask: Decimal(string: ask)!,
            bid: Decimal(string: bid)!,
            book: "usdc_brl",
            date: Date(timeIntervalSince1970: 1_700_000_500)
        )
    }

    @Test
    func initial_state_is_idle_with_fallback_currencies_and_default_selection() async {
        let service = MockRateService()
        let viewModel = ExchangeViewModel(service: service)

        #expect(viewModel.state == .idle)
        #expect(viewModel.availableCurrencies.map(\.code) == ["MXN", "ARS", "BRL", "COP"])
        #expect(viewModel.selectedCurrency.code == "MXN")
        #expect(viewModel.usdcInput == "")
        #expect(viewModel.foreignInput == "")
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
        #expect(viewModel.availableCurrencies.map(\.code) == ["MXN", "ARS", "BRL", "COP"])
    }

    @Test
    func editing_usdc_recomputes_foreign_using_mid() async {
        let service = MockRateService()
        await service.setTickerResult(.success([Self.tickerMXN(ask: "20", bid: "18")]))
        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()

        viewModel.didEditUSDc("10")

        let mid: Decimal = (Decimal(20) + Decimal(18)) / 2
        let expected = DecimalFormatting.display(Decimal(10) * mid, locale: Locale(identifier: "en_US_POSIX"))
        let actual = DecimalFormatting.display(
            DecimalFormatting.parse(viewModel.foreignInput, locale: Locale(identifier: "en_US_POSIX")) ?? 0,
            locale: Locale(identifier: "en_US_POSIX")
        )
        #expect(actual == expected)
        #expect(viewModel.activeEditor == .fromUSDc)
    }

    @Test
    func editing_foreign_recomputes_usdc_using_mid() async {
        let service = MockRateService()
        await service.setTickerResult(.success([Self.tickerMXN(ask: "20", bid: "18")]))
        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()

        viewModel.didEditForeign("190")

        let mid: Decimal = (Decimal(20) + Decimal(18)) / 2
        let expectedUsdc = Decimal(190) / mid
        let parsed = DecimalFormatting.parse(viewModel.usdcInput, locale: Locale(identifier: "en_US_POSIX")) ?? 0

        var diff = parsed - expectedUsdc
        if diff < 0 { diff = -diff }
        #expect(diff < Decimal(string: "0.000001")!)
        #expect(viewModel.activeEditor == .toUSDc)
    }

    @Test
    func empty_input_clears_other_field() async {
        let service = MockRateService()
        await service.setTickerResult(.success([Self.tickerMXN()]))
        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()

        viewModel.didEditUSDc("10")
        #expect(viewModel.foreignInput.isEmpty == false)

        viewModel.didEditUSDc("")
        #expect(viewModel.foreignInput == "")
    }

    @Test
    func non_numeric_input_clears_other_field() async {
        let service = MockRateService()
        await service.setTickerResult(.success([Self.tickerMXN()]))
        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()

        viewModel.didEditUSDc("abcdef")
        #expect(viewModel.foreignInput == "")
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
    func swap_flips_visual_layout_and_active_editor_keeping_inputs_attached_to_their_currency() async {
        let service = MockRateService()
        await service.setTickerResult(.success([Self.tickerMXN()]))
        let viewModel = ExchangeViewModel(service: service)
        await viewModel.bootstrap()

        viewModel.didEditUSDc("10")
        let usdcBefore = viewModel.usdcInput
        let foreignBefore = viewModel.foreignInput
        #expect(viewModel.usdcOnTop)
        #expect(viewModel.activeEditor == .fromUSDc)

        viewModel.swap()

        #expect(viewModel.usdcOnTop == false)
        #expect(viewModel.activeEditor == .toUSDc)
        #expect(viewModel.usdcInput == usdcBefore)
        #expect(viewModel.foreignInput == foreignBefore)

        viewModel.swap()
        #expect(viewModel.usdcOnTop == true)
        #expect(viewModel.activeEditor == .fromUSDc)
    }
}
