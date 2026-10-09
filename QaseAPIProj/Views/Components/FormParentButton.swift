import UIKit
import SnapKit

final class FormParentButton: UIButton {
    private let caption = UILabel()
    private let valueLabel = UILabel()
    private let pathLabel = UILabel()
    private let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))

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
        text.spacing = 4
        text.isUserInteractionEnabled = false
        addSubview(text)
        addSubview(arrow)
        text.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(12)
            $0.trailing.equalTo(arrow.snp.leading).offset(-12)
        }
        arrow.snp.makeConstraints {
            $0.trailing.centerY.equalToSuperview()
            $0.width.equalTo(12)
            $0.height.equalTo(16)
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(52) }
        accessibilityIdentifier = "field." + FieldType.parentSuite.rawValue
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(title: String, path: String) {
        valueLabel.text = title
        pathLabel.text = path
        pathLabel.isHidden = path.isEmpty
        accessibilityLabel = [FieldType.parentSuite.localized, title, path].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    override var isEnabled: Bool {
        didSet { alpha = isEnabled ? 1 : 0.5 }
    }
}
