import UIKit
import SnapKit

final class TestCaseStepView: UIView {
    private let step: StepsInTestCase
    private let action = UILabel()
    private let expected = UILabel()

    init(step: StepsInTestCase, number: String) {
        self.step = step
        super.init(frame: .zero)
        backgroundColor = AppTheme.Palette.secondarySurface
        layer.cornerRadius = AppTheme.Radius.card
        let numberLabel = UILabel()
        numberLabel.text = number
        numberLabel.font = .preferredFont(forTextStyle: .footnote)
        numberLabel.adjustsFontForContentSizeCategory = true
        numberLabel.textColor = AppTheme.Palette.accent
        numberLabel.textAlignment = .center
        numberLabel.isAccessibilityElement = false
        let badge = UIView()
        badge.backgroundColor = AppTheme.Palette.accent.withAlphaComponent(0.12)
        badge.layer.cornerRadius = AppTheme.Radius.badge
        badge.addSubview(numberLabel)
        numberLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(8) }
        badge.snp.makeConstraints { $0.width.height.greaterThanOrEqualTo(32) }
        badge.setContentHuggingPriority(.required, for: .horizontal)
        let body = UIStackView(arrangedSubviews: [
            caption("Action"), action, caption("Expected result"), expected
        ])
        body.axis = .vertical
        body.spacing = 6
        body.setCustomSpacing(12, after: action)
        for label in [action, expected] {
            label.font = .preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.textColor = AppTheme.Palette.text
            label.isAccessibilityElement = false
        }
        addSubview(badge)
        addSubview(body)
        badge.snp.makeConstraints {
            $0.leading.top.equalToSuperview().inset(16)
        }
        body.snp.makeConstraints {
            $0.top.bottom.trailing.equalToSuperview().inset(16)
            $0.leading.equalTo(badge.snp.trailing).offset(12)
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(badge.snp.height).offset(32) }
        updateText()
        isAccessibilityElement = true
        accessibilityLabel = [number, "Action".localized, action.attributedText?.string ?? action.text ?? "",
            "Expected result".localized, expected.attributedText?.string ?? expected.text ?? ""].joined(separator: ", ")
        accessibilityIdentifier = "case.step." + number
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            value.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .body),
                range: NSRange(location: 0, length: value.length))
            label.attributedText = value
        } else {
            label.text = text
        }
    }

    private func updateText() {
        setText(step.action, in: action, fallback: "Action not provided")
        setText(step.expectedResult, in: expected, fallback: "Expected result not provided")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateText()
    }
}
