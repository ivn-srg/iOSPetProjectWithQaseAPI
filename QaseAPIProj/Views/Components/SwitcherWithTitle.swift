import SnapKit
import UIKit

final class SwitcherWithTitle: UIView {
    var switchValueChanged: ((Bool) -> Void)?
    private let switcher = UISwitch()

    init(title: String, isOn: Bool) {
        super.init(frame: .zero)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        titleLabel.textColor = AppTheme.Palette.text
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        let helper = UILabel()
        helper.text = "May fail without changes in conditions".localized
        helper.font = UIFont.preferredFont(forTextStyle: .caption1)
        helper.textColor = AppTheme.Palette.secondaryText
        helper.numberOfLines = 0
        helper.adjustsFontForContentSizeCategory = true
        let labels = UIStackView(arrangedSubviews: [titleLabel, helper])
        labels.axis = .vertical
        labels.spacing = AppTheme.Space.tiny
        addSubview(labels)
        addSubview(switcher)
        switcher.onTintColor = AppTheme.Palette.accent
        switcher.accessibilityIdentifier = AccessibilityID.field(.isFlaky).identifier
        switcher.accessibilityLabel = title
        switcher.accessibilityHint = helper.text
        titleLabel.isAccessibilityElement = false
        helper.isAccessibilityElement = false
        labels.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(AppTheme.Space.medium)
            $0.trailing.equalTo(switcher.snp.leading).offset(-AppTheme.Space.regular)
        }
        switcher.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(titleLabel)
            $0.bottom.lessThanOrEqualToSuperview().inset(AppTheme.Space.medium)
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(Layout.minimumRowHeight) }
        switcher.isOn = isOn
        switcher.addTarget(self, action: #selector(switchValueDidChange(_:)), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func switchValueDidChange(_ sender: UISwitch) {
        switchValueChanged?(sender.isOn)
    }

    func configure(with isOn: Bool) {
        switcher.isOn = isOn
    }

    func setEditingEnabled(_ enabled: Bool) {
        switcher.isEnabled = enabled
    }
}

private struct Layout {
    static let minimumRowHeight: CGFloat = 52
}
