import SnapKit
import UIKit

final class FormParentButton: UIButton {
    private let caption = UILabel()
    private let valueLabel = UILabel()
    private let pathLabel = UILabel()
    private let arrow = UIImageView(image: AppImages.chevronRight)

    override init(frame: CGRect) {
        super.init(frame: frame)
        caption.text = FieldType.parentSuite.localized
        caption.font = .preferredFont(forTextStyle: .footnote)
        caption.textColor = AppTheme.Palette.secondaryText
        valueLabel.font = .preferredFont(forTextStyle: .body)
        valueLabel.textColor = AppTheme.Palette.text
        pathLabel.font = .preferredFont(forTextStyle: .footnote)
        pathLabel.textColor = AppTheme.Palette.secondaryText
        for label in [caption, valueLabel, pathLabel] {
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
            label.isAccessibilityElement = false
        }
        arrow.tintColor = AppTheme.Palette.secondaryText
        arrow.contentMode = .scaleAspectFit
        let text = UIStackView(arrangedSubviews: [caption, valueLabel, pathLabel])
        text.axis = .vertical
        text.spacing = AppTheme.Space.tiny
        text.isUserInteractionEnabled = false
        addSubview(text)
        addSubview(arrow)
        text.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(AppTheme.Space.medium)
            $0.trailing.equalTo(arrow.snp.leading).offset(-AppTheme.Space.medium)
        }
        arrow.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
            $0.width.equalTo(Layout.chevronWidth)
            $0.height.equalTo(Layout.chevronHeight)
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(Layout.minimumRowHeight) }
        accessibilityIdentifier = AccessibilityID.field(.parentSuite).identifier
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(title: String, path: String) {
        valueLabel.text = title
        pathLabel.text = path
        pathLabel.isHidden = path.isEmpty
        accessibilityLabel = [FieldType.parentSuite.localized, title, path].filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    override var isEnabled: Bool {
        didSet { alpha = isEnabled ? 1 : Layout.disabledOpacity }
    }
}

private struct Layout {
    static let disabledOpacity: CGFloat = 0.5
    static let chevronWidth: CGFloat = 12
    static let chevronHeight: CGFloat = 16
    static let minimumRowHeight: CGFloat = 52
}
