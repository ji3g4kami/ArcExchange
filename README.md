# ArcExchange

A USDc ↔ fiat exchange-rate calculator for iOS, built with SwiftUI and Swift Concurrency. Take-home submission against [`Requirements.md`](Requirements.md).

---

## How to run

**Requirements**

- Xcode 26 or newer
- iOS 26.4 simulator runtime (matches `IPHONEOS_DEPLOYMENT_TARGET = 26.4`)
- Swift 5

**The app**

1. `git clone git@github.com:ji3g4kami/ArcExchange.git`
2. Open `ArcExchange.xcodeproj`
3. Pick an iOS 26.4 simulator
4. ⌘R

No Swift Package fetch, no API keys, no extra config.

**Tests**

- In Xcode: ⌘U
- From the command line:

  ```bash
  xcodebuild test \
    -scheme ArcExchange \
    -destination "platform=iOS Simulator,name=iPhone 17"
  ```

UI tests launch the app with `-UITestStubSuccess`, which routes the rate service through an in-process stub so the suite is deterministic and offline. See `ArcExchangeUITests/ExchangeFlowUITests.swift`.

---

## Requirements checklist

Mapped 1:1 to [`Requirements.md`](Requirements.md):

- [x] **Two input fields, one for USDc and one for the selected currency** — `ArcExchange/Views/CurrencyFieldView.swift`, wired in `ArcExchange/Views/ExchangeScreen.swift`
- [x] **Editing either field updates the other** — `ArcExchange/ViewModel/ExchangeViewModel.swift` (`recompute()`); conversion math in `ArcExchange/Domain/CurrencyConverter.swift`
- [x] **Tapping the non-USDc currency opens a bottom sheet to pick a different one** — `ArcExchange/Views/CurrencyPickerSheet.swift` (`.presentationDetents([.medium, .large])`)
- [x] **Swap button between the two currency fields** — `ArcExchange/Views/SwapButton.swift`; toggles `usdcOnTop` and `activeEditor` in the view model
- [x] **Fetch rates from `GET /v1/tickers?currencies=…`** — `ArcExchange/Services/LiveRateService.swift`
- [x] **Handle the unavailable `/v1/tickers-currencies` endpoint** — `ArcExchange/Domain/CurrencyCatalog.swift` catches the failure and falls back to `Currency.fallbackCodes` (`["MXN", "ARS", "BRL", "COP", "EURc"]`)
- [x] **Fully functional end-to-end** — launch, type, swap, switch currency, pull-to-refresh, recover from network errors

---

## Beyond the brief

### Polish / UX

- Custom "arc" wordmark app icon with Light, Dark and Tinted variants (`ArcExchange/Assets.xcassets/AppIcon.appiconset`)
- Dark-mode-aware color sets in `ArcExchange/Assets.xcassets/Colors/`
- Pull-to-refresh on the exchange screen (`.refreshable { await viewModel.refresh() }`)
- Animated swap button (180° rotation on tap)
- Inline error banner with a Retry action — `ArcExchange/Views/ErrorBanner.swift`

### Correctness

- Decimal-precision-safe text input — `ArcExchange/Domain/AmountInput.swift` sanitises typed characters and caps integer digits at 30
- Per-currency fractional precision — `Currency.fractionDigitLimit` (6 for USDc, 2 for fiat)
- Mid-rate computed as `(bid + ask) / 2` — `ArcExchange/Models/ExchangeRate.swift`
- Explicit load-state machine — `ArcExchange/ViewModel/LoadState.swift` (`idle / loading / loaded / failed`)

### Architecture

- SwiftUI + Swift Concurrency throughout — no GCD, no Combine
- Typed service errors — `ArcExchange/Services/RateServiceError.swift` (`invalidURL`, `http`, `decoding`, `transport`)
- Hardened networking in `LiveRateService.swift` — 15 s request timeout, 60 s resource timeout, 1 MB response cap

### Testing

**Unit tests (Swift Testing)** under `ArcExchangeTests/`:

- `AmountInputTests` — input sanitisation and precision capping
- `CurrencyCatalogTests` — fallback behaviour when the currencies endpoint fails
- `CurrencyConverterTests` — conversion math in both directions
- `ExchangeRateTests` — mid-rate derivation
- `ExchangeViewModelTests` — state transitions, swap, recompute
- `LiveRateServiceTests` — URL building and response handling
- `TickerDecodingTests` — JSON decoding of the live API shape

**UI tests** under `ArcExchangeUITests/`:

- `ExchangeFlowUITests` — launch, amount entry, swap, currency selection, error / offline paths
- Deterministic via `-UITestStubSuccess` plus semantic identifiers in `ArcExchange/Support/AccessibilityID.swift`

**SwiftUI previews** cover Loaded, Failed, Loading and Dark variants of the main screen.

---

## Project structure

```
ArcExchange/
├── ArcExchangeApp.swift      App entry point
├── Domain/                   Pure logic — AmountInput, CurrencyConverter, CurrencyCatalog
├── Models/                   Currency, ExchangeRate, Ticker DTO
├── Services/                 LiveRateService, RateServiceError
├── ViewModel/                ExchangeViewModel, LoadState
├── Views/                    ExchangeScreen, CurrencyFieldView, CurrencyPickerSheet, SwapButton, ErrorBanner
├── Support/                  AccessibilityID and shared helpers
└── Assets.xcassets           App icon variants, color sets
```

---

## Notes for the reviewer

- Deployment target is iOS 26.4 — please make sure a matching simulator runtime is installed.
- `/v1/tickers-currencies` is exercised through its failure path on purpose, since the endpoint isn't live yet. The app degrades to a static currency list rather than blocking the UI.
