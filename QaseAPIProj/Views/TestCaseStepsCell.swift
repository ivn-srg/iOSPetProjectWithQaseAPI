import SnapKit
import UIKit

final class TestCaseStepView: UIView {
    private struct Layout {
        static let contentInset = AppTheme.Space.regular
        static let bodySpacing = AppTheme.Space.medium
        static let captionSpacing: CGFloat = 6
        static let badgeOpacity: CGFloat = 0.12
    }

    private let step: StepsInTestCase
    private let action = UILabel()
    private let expected = UILabel()
    private let badge: StepNumberBadge
    private let body = UIStackView()

    init(step: StepsInTestCase, number: String) {
        self.step = step
        badge = StepNumberBadge(number: number)
        super.init(frame: .zero)
        backgroundColor = AppTheme.Palette.secondarySurface
        layer.cornerRadius = AppTheme.Radius.card
        body.axis = .vertical
        body.spacing = Layout.captionSpacing
        for label in [action, expected] {
            label.font = .preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textColor = AppTheme.Palette.text
            label.isAccessibilityElement = false
        }
        [caption("Action"), action, caption("Expected result"), expected].forEach(body.addArrangedSubview)
        body.setCustomSpacing(Layout.bodySpacing, after: action)
        addSubview(badge)
        addSubview(body)
        registerForTraitChanges([
            UITraitPreferredContentSizeCategory.self,
            UITraitUserInterfaceStyle.self
        ]) { (view: Self, _) in
            view.refreshTraits()
        }
        refreshTraits()
        isAccessibilityElement = true
        accessibilityLabel = [
            number,
            "Action".localized,
            action.attributedText?.string ?? action.text ?? "",
            "Expected result".localized,
            expected.attributedText?.string ?? expected.text ?? ""
        ].joined(separator: ", ")
        accessibilityIdentifier = AccessibilityID.step(number).identifier
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func refreshTraits() {
        badge.refreshFont()
        updateText()
        let vertical = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        badge.snp.remakeConstraints {
            $0.leading.top.equalToSuperview().inset(Layout.contentInset)
            $0.trailing.lessThanOrEqualToSuperview().inset(Layout.contentInset)
            $0.bottom.lessThanOrEqualToSuperview().inset(Layout.contentInset)
        }
        body.snp.remakeConstraints {
            $0.trailing.bottom.equalToSuperview().inset(Layout.contentInset)
            if vertical {
                $0.leading.equalToSuperview().inset(Layout.contentInset)
                $0.top.equalTo(badge.snp.bottom).offset(Layout.bodySpacing)
            } else {
                $0.top.equalToSuperview().inset(Layout.contentInset)
                $0.leading.equalTo(badge.snp.trailing).offset(Layout.bodySpacing)
            }
        }
    }

    private func caption(_ key: String) -> UILabel {
        let label = UILabel()
        label.text = key.localized
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = AppTheme.Palette.secondaryText
        label.isAccessibilityElement = false
        return label
    }

    private func setText(_ text: String?, in label: UILabel, fallback: String) {
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            label.attributedText = nil
            label.text = fallback.localized
            label.textColor = AppTheme.Palette.secondaryText
            return
        }
        label.textColor = AppTheme.Palette.text
        if let rendered = text.toAttributedString() {
            let value = NSMutableAttributedString(attributedString: rendered)
            value.addAttribute(
                .font,
                value: UIFont.preferredFont(forTextStyle: .body, compatibleWith: traitCollection),
                range: NSRange(location: 0, length: value.length)
            )
            label.attributedText = value
        } else {
            label.text = text
        }
    }

    private func updateText() {
        setText(step.action, in: action, fallback: "Action not provided")
        setText(step.expectedResult, in: expected, fallback: "Expected result not provided")
    }
}

private final class StepNumberBadge: UIView {
    private struct Layout {
        static let padding = AppTheme.Space.small
        static let minimum = AppTheme.Space.large
        static let opacity: CGFloat = 0.12
    }

    private let label = UILabel()

    init(number: String) {
        super.init(frame: .zero)
        label.text = number
        label.textColor = AppTheme.Palette.accent
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.isAccessibilityElement = false
        backgroundColor = AppTheme.Palette.accent.withAlphaComponent(Layout.opacity)
        layer.cornerRadius = AppTheme.Radius.badge
        addSubview(label)
        label.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.greaterThanOrEqualToSuperview().inset(Layout.padding)
            $0.trailing.lessThanOrEqualToSuperview().inset(Layout.padding)
        }
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        refreshFont()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var intrinsicContentSize: CGSize {
        let size = label.intrinsicContentSize
        return CGSize(
            width: max(Layout.minimum, size.width + Layout.padding * 2),
            height: max(Layout.minimum, size.height + Layout.padding * 2)
        )
    }

    func refreshFont() {
        label.font = .preferredFont(forTextStyle: .footnote, compatibleWith: traitCollection)
        invalidateIntrinsicContentSize()
    }
}
