import Foundation

enum A11yID {
    static let usdcField   = "amount.usdc"
    static let foreignField = "amount.foreign"
    static let usdcLabel   = "label.usdc"
    static let foreignLabel = "label.foreign"
    static let swapButton  = "button.swap"
    static let pickerSheet = "sheet.currencyPicker"
    static let errorBanner = "banner.error"
    static let retryButton = "button.retry"
    static let lastUpdated = "text.lastUpdated"
    static let rateLine    = "text.rateLine"

    static func pickerRow(_ code: String) -> String { "picker.row.\(code)" }
}
