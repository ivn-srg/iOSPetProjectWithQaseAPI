import UIKit
import SnapKit

final class CustomSelectableView: UIButton {
    private let textFieldType: FieldType
    private let viewModel: UpdatableEntityProtocol?
    private var selectableValue: MenuItem?
    private var isVertical = false
    private let titleLbl = UILabel()
    private let valueLabel = UILabel()
    private let valueGroup = UIView()
    private let marker = UIView()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    private var draft: TestCaseEntity? {
        if let creating = viewModel as? CreateSuiteOrCaseViewModel {
            return creating.creatingTestCase
        }
        return viewModel?.changedTestCase ?? viewModel?.testCase
    }

    private var dataSource: [MenuItem] {
        switch textFieldType {
        case .severity: Severity.dataSource
        case .status: Status.dataSource
        case .priority: Priority.dataSource
        case .behavior: Behavior.dataSource
        case .type: Types.dataSource
        case .layer: Layer.dataSource
        case .automation: AutomationStatus.dataSource
        default: []
        }
    }

    init(textFieldType: FieldType, detailCaseVM: UpdatableEntityProtocol?) {
        self.textFieldType = textFieldType
        viewModel = detailCaseVM
        super.init(frame: .zero)
        titleLbl.text = textFieldType.localized
        for label in [titleLbl, valueLabel] {
            label.font = UIFont.preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            label.isAccessibilityElement = false
        }
        titleLbl.textColor = AppTheme.Palette.text
        valueLabel.textColor = AppTheme.Palette.text
        valueGroup.isUserInteractionEnabled = false
        chevron.tintColor = AppTheme.Palette.tertiaryText
        chevron.contentMode = .scaleAspectFit
        marker.layer.cornerRadius = 3
        addSubview(titleLbl)
        addSubview(valueGroup)
        addSubview(chevron)
        valueGroup.addSubview(valueLabel)
        valueGroup.addSubview(marker)
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(52) }
        chevron.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.width.equalTo(12)
            $0.height.equalTo(16)
            $0.centerY.equalTo(titleLbl.snp.firstBaseline).offset(-titleLbl.font.capHeight / 2)
        }
        titleLbl.setContentCompressionResistancePriority(.required, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        isAccessibilityElement = true
        accessibilityIdentifier = "field." + textFieldType.rawValue
        accessibilityLabel = textFieldType.localized
        showsMenuAsPrimaryAction = true
        updateSelectedValue()
        applyLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        let available = bounds.width - 28
        let measuringSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let needed = titleLbl.sizeThatFits(measuringSize).width + valueLabel.sizeThatFits(measuringSize).width + (marker.isHidden ? 0 : 12) + 16
        let vertical = traitCollection.preferredContentSizeCategory.isAccessibilityCategory || needed > available
        if vertical != isVertical {
            isVertical = vertical
            applyLayout()
        }
        super.layoutSubviews()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        chevron.snp.updateConstraints {
            $0.centerY.equalTo((isVertical ? valueLabel : titleLbl).snp.firstBaseline)
                .offset(-(isVertical ? valueLabel : titleLbl).font.capHeight / 2)
        }
        marker.snp.updateConstraints {
            $0.centerY.equalTo(valueLabel.snp.firstBaseline).offset(-valueLabel.font.capHeight / 2)
        }
        setNeedsLayout()
    }

    private func applyLayout() {
        let compression: UILayoutPriority = isVertical ? .defaultHigh : .required
        titleLbl.setContentCompressionResistancePriority(compression, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(compression, for: .horizontal)
        titleLbl.snp.remakeConstraints {
            $0.leading.equalToSuperview()
            $0.top.equalToSuperview().offset(12)
            if isVertical {
                $0.trailing.equalTo(chevron.snp.leading).offset(-12)
            } else {
                $0.bottom.equalToSuperview().inset(12)
                $0.trailing.lessThanOrEqualTo(valueGroup.snp.leading).offset(-16)
            }
        }
        valueGroup.snp.remakeConstraints {
            if isVertical {
                $0.leading.equalToSuperview()
                $0.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-12)
                $0.top.equalTo(titleLbl.snp.bottom).offset(6)
                $0.bottom.equalToSuperview().inset(12)
            } else {
                $0.trailing.equalTo(chevron.snp.leading).offset(-12)
                $0.centerY.equalTo(titleLbl)
                $0.top.greaterThanOrEqualToSuperview().offset(12)
                $0.bottom.lessThanOrEqualToSuperview().inset(12)
            }
        }
        valueLabel.snp.remakeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.trailing.equalTo(marker.snp.leading).offset(marker.isHidden ? 0 : -6)
        }
        marker.snp.remakeConstraints {
            $0.trailing.equalToSuperview()
            $0.width.height.equalTo(marker.isHidden ? 0 : 6)
            $0.centerY.equalTo(valueLabel.snp.firstBaseline).offset(-valueLabel.font.capHeight / 2)
        }
        chevron.snp.remakeConstraints {
            $0.trailing.equalToSuperview()
            $0.width.equalTo(12)
            $0.height.equalTo(16)
            $0.centerY.equalTo((isVertical ? valueLabel : titleLbl).snp.firstBaseline)
                .offset(-(isVertical ? valueLabel : titleLbl).font.capHeight / 2)
        }
        valueLabel.textAlignment = isVertical ? .natural : .right
    }

    private func selectedItem() -> MenuItem? {
        guard let draft else { return nil }
        switch textFieldType {
        case .severity: return draft.severity.menuItem
        case .status: return draft.status.menuItem
        case .priority: return draft.priority.menuItem
        case .behavior: return draft.behavior.menuItem
        case .type: return draft.type.menuItem
        case .layer: return draft.layer.menuItem
        case .automation: return draft.automation.menuItem
        default: return nil
        }
    }

    static func markerColor(for field: FieldType, id: Int?) -> UIColor? {
        switch (field, id) {
        case (.priority, 1): AppTheme.Palette.warning
        case (.priority, 2): AppTheme.Palette.info
        case (.priority, 3): AppTheme.Palette.secondaryText
        case (.severity, 1), (.severity, 2), (.severity, 3): AppTheme.Palette.danger
        case (.severity, 4): AppTheme.Palette.info
        case (.severity, 5), (.severity, 6): AppTheme.Palette.success
        default: nil
        }
    }

    private func renderSelection() {
        valueLabel.text = selectableValue?.title ?? Constants.EMPTY_TEXT
        marker.backgroundColor = Self.markerColor(for: textFieldType, id: selectableValue?.id)
        marker.isHidden = marker.backgroundColor == nil
        accessibilityValue = valueLabel.text
        menu = UIMenu(children: dataSource.map { item in
            UIAction(title: item.title, image: item.image, state: item.id == selectableValue?.id ? .on : .off) { [weak self] _ in
                guard let self else { return }
                selectableValue = item
                updateTestCaseData()
                updateSelectedValue()
            }
        })
        applyLayout()
        setNeedsLayout()
    }

    func updateTestCaseData() {
        guard let selectableValue else { return }
        viewModel?.updateValue(for: textFieldType, value: selectableValue.id)
    }

    func updateSelectedValue() {
        selectableValue = selectedItem()
        renderSelection()
    }

    func setEditingEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
}
