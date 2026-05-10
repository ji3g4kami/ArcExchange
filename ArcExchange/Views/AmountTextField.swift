import SwiftUI
import UIKit

struct AmountTextField: UIViewRepresentable {
    @Binding var amount: Decimal?
    @Binding var isFocused: Bool
    let fractionDigitLimit: Int
    let placeholder: String
    let isEnabled: Bool
    let accessibilityIdentifier: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> AmountInputContainerView {
        let container = AmountInputContainerView()
        container.textField.delegate = context.coordinator
        container.textField.placeholder = placeholder
        container.textField.accessibilityIdentifier = accessibilityIdentifier
        container.textField.text = AmountInput.displayGrouped(
            forAmount: amount,
            fractionDigitLimit: fractionDigitLimit
        )
        container.applyEmptyState(amount == nil)
        container.invalidateIntrinsicContentSize()
        return container
    }

    func updateUIView(_ container: AmountInputContainerView, context: Context) {
        context.coordinator.parent = self
        container.textField.isEnabled = isEnabled
        container.textField.placeholder = placeholder
        container.textField.accessibilityIdentifier = accessibilityIdentifier
        if !container.textField.isEditing {
            let target = AmountInput.displayGrouped(
                forAmount: amount,
                fractionDigitLimit: fractionDigitLimit
            )
            if container.textField.text != target {
                container.textField.text = target
                container.invalidateIntrinsicContentSize()
                container.setNeedsLayout()
            }
        }
        container.applyEmptyState(amount == nil)
        if isFocused && !container.textField.isFirstResponder {
            container.textField.becomeFirstResponder()
        } else if !isFocused && container.textField.isFirstResponder {
            container.textField.resignFirstResponder()
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: AmountInputContainerView, context: Context) -> CGSize? {
        let intrinsic = uiView.intrinsicContentSize
        let width = min(intrinsic.width, proposal.width ?? .infinity)
        return CGSize(width: width, height: intrinsic.height)
    }

    @MainActor
    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: AmountTextField

        init(parent: AmountTextField) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            if !parent.isFocused { parent.isFocused = true }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if parent.isFocused { parent.isFocused = false }
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            let oldText = textField.text ?? ""
            guard let oldRange = Range(range, in: oldText) else { return false }
            let proposed = oldText.replacingCharacters(in: oldRange, with: string)

            let sanitized = AmountInput.sanitize(proposed)
            let limited = AmountInput.limitFraction(sanitized, max: parent.fractionDigitLimit)

            let insertEndOffset = range.location + (string as NSString).length
            let safeOffset = min(insertEndOffset, proposed.count)
            let prefixEnd = proposed.index(proposed.startIndex, offsetBy: safeOffset)
            let logicalRaw = AmountInput.logicalCursor(in: String(proposed[..<prefixEnd]))
            let logical = min(logicalRaw, limited.count)

            let formatted = AmountInput.displayGrouped(forSanitized: limited)
            textField.text = formatted

            if let container = textField.superview as? AmountInputContainerView {
                container.invalidateIntrinsicContentSize()
                container.setNeedsLayout()
            }

            let displayOffset = AmountInput.displayCursorOffset(
                forFormatted: formatted,
                logicalCursor: logical
            )
            if let position = textField.position(
                from: textField.beginningOfDocument,
                offset: displayOffset
            ) {
                textField.selectedTextRange = textField.textRange(from: position, to: position)
            }

            let parsed = AmountInput.parse(limited)
            if parsed != parent.amount {
                parent.amount = parsed
            }
            return false
        }
    }
}

@MainActor
final class AmountInputContainerView: UIView {
    let dollarLabel = UILabel()
    let textField = UITextField()

    private let baseFontSize: CGFloat = 16
    private let minFontSize: CGFloat = 10
    private let spacing: CGFloat = 2

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        let baseFont = UIFont.systemFont(ofSize: baseFontSize, weight: .bold)
        dollarLabel.text = "$"
        dollarLabel.font = baseFont
        dollarLabel.textColor = .label
        dollarLabel.textAlignment = .left
        addSubview(dollarLabel)

        textField.font = baseFont
        textField.textColor = .label
        textField.textAlignment = .left
        textField.keyboardType = .decimalPad
        textField.adjustsFontSizeToFitWidth = false
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        addSubview(textField)
    }

    func applyEmptyState(_ isEmpty: Bool) {
        dollarLabel.textColor = isEmpty ? .secondaryLabel : .label
    }

    private func displayedDigits() -> String {
        let text = textField.text ?? ""
        return text.isEmpty ? (textField.placeholder ?? "") : text
    }

    private func widths(at fontSize: CGFloat) -> (dollar: CGFloat, digits: CGFloat) {
        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        let dollar = ("$" as NSString).size(withAttributes: [.font: font]).width
        let digits = (displayedDigits() as NSString).size(withAttributes: [.font: font]).width
        return (ceil(dollar), ceil(digits))
    }

    override var intrinsicContentSize: CGSize {
        let (dollarWidth, digitsWidth) = widths(at: baseFontSize)
        let baseFont = UIFont.systemFont(ofSize: baseFontSize, weight: .bold)
        let height = ceil(baseFont.lineHeight)
        return CGSize(width: dollarWidth + spacing + digitsWidth, height: height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let (baseDollarWidth, baseDigitsWidth) = widths(at: baseFontSize)
        let baseTotal = baseDollarWidth + spacing + baseDigitsWidth
        let availableWidth = bounds.width

        let scale: CGFloat
        if baseTotal <= availableWidth || baseTotal == 0 {
            scale = 1
        } else {
            scale = max(minFontSize / baseFontSize, availableWidth / baseTotal)
        }

        let scaledFontSize = baseFontSize * scale
        let scaledFont = UIFont.systemFont(ofSize: scaledFontSize, weight: .bold)
        if dollarLabel.font.pointSize != scaledFontSize { dollarLabel.font = scaledFont }
        if textField.font?.pointSize != scaledFontSize { textField.font = scaledFont }

        let (scaledDollarWidth, scaledDigitsWidth) = widths(at: scaledFontSize)
        let totalScaled = scaledDollarWidth + spacing + scaledDigitsWidth
        let leadingX = max(0, bounds.width - totalScaled)

        dollarLabel.frame = CGRect(x: leadingX, y: 0, width: scaledDollarWidth, height: bounds.height)
        textField.frame = CGRect(
            x: leadingX + scaledDollarWidth + spacing,
            y: 0,
            width: max(0, bounds.width - leadingX - scaledDollarWidth - spacing),
            height: bounds.height
        )
    }
}
