import SnapKit
import UIKit

final class CustomSelectableView: UIButton {
    private let textFieldType: FieldType
    private let viewModel: UpdatableEntityProtocol?
    private var selectableValue: MenuItem?
    private var isVertical = false
    private let titleLbl = UILabel()
    private let valueLabel = UILabel()
    private let valueGroup = UIView()
    private let marker = UIView()
    private let chevron = UIImageView(image: AppImages.chevronRight)

    private var draft: TestCaseEntity? { viewModel?.formCase }

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
        marker.layer.cornerRadius = Layout.markerRadius
        addSubview(titleLbl)
        addSubview(valueGroup)
        addSubview(chevron)
        valueGroup.addSubview(valueLabel)
        valueGroup.addSubview(marker)
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(Layout.minimumRowHeight) }
        chevron.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.width.equalTo(Layout.chevronWidth)
            $0.height.equalTo(Layout.chevronHeight)
            $0.centerY.equalTo(titleLbl.snp.firstBaseline).offset(-titleLbl.font.capHeight / 2)
        }
        titleLbl.setContentCompressionResistancePriority(.required, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityID.field(textFieldType.accessibilityField).identifier
        accessibilityLabel = textFieldType.localized
        showsMenuAsPrimaryAction = true
        updateSelectedValue()
        registerForTraitChanges([
            UITraitUserInterfaceStyle.self,
            UITraitPreferredContentSizeCategory.self
        ]) { (view: Self, _) in
            view.refreshTraits()
        }
        applyLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        let available = bounds.width - Layout.reservedWidth
        let measuringSize = CGSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        let needed = titleLbl.sizeThatFits(measuringSize).width + valueLabel.sizeThatFits(measuringSize)
            .width + (marker.isHidden ? 0 : AppTheme.Space.medium) + AppTheme.Space.regular
        let vertical = traitCollection.preferredContentSizeCategory
            .isAccessibilityCategory || needed > available
        if vertical != isVertical {
            isVertical = vertical
            applyLayout()
        }
        super.layoutSubviews()
    }

    private func refreshTraits() {
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
            $0.top.equalToSuperview().offset(AppTheme.Space.medium)
            if isVertical {
                $0.trailing.equalTo(chevron.snp.leading).offset(-AppTheme.Space.medium)
            } else {
                $0.bottom.equalToSuperview().inset(AppTheme.Space.medium)
                $0.trailing.lessThanOrEqualTo(valueGroup.snp.leading).offset(-AppTheme.Space.regular)
            }
        }
        valueGroup.snp.remakeConstraints {
            if isVertical {
                $0.leading.equalToSuperview()
                $0.trailing.lessThanOrEqualTo(chevron.snp.leading).offset(-AppTheme.Space.medium)
                $0.top.equalTo(titleLbl.snp.bottom).offset(Layout.verticalValueSpacing)
                $0.bottom.equalToSuperview().inset(AppTheme.Space.medium)
            } else {
                $0.trailing.equalTo(chevron.snp.leading).offset(-AppTheme.Space.medium)
                $0.centerY.equalTo(titleLbl)
                $0.top.greaterThanOrEqualToSuperview().offset(AppTheme.Space.medium)
                $0.bottom.lessThanOrEqualToSuperview().inset(AppTheme.Space.medium)
            }
        }
        valueLabel.snp.remakeConstraints {
            $0.leading.top.bottom.equalToSuperview()
            $0.trailing.equalTo(marker.snp.leading).offset(marker.isHidden ? 0 : -Layout.markerSize)
        }
        marker.snp.remakeConstraints {
            $0.trailing.equalToSuperview()
            $0.width.height.equalTo(marker.isHidden ? 0 : Layout.markerSize)
            $0.centerY.equalTo(valueLabel.snp.firstBaseline).offset(-valueLabel.font.capHeight / 2)
        }
        chevron.snp.remakeConstraints {
            $0.trailing.equalToSuperview()
            $0.width.equalTo(Layout.chevronWidth)
            $0.height.equalTo(Layout.chevronHeight)
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
        guard let id else { return nil }
        switch field {
        case .priority:
            switch Priority(id) {
            case .high: return AppTheme.Palette.warning
            case .medium: return AppTheme.Palette.info
            case .low: return AppTheme.Palette.secondaryText
            case .nothing: return nil
            }
        case .severity:
            switch Severity(id) {
            case .blocker, .critical, .major: return AppTheme.Palette.danger
            case .normal: return AppTheme.Palette.info
            case .minor, .trivial: return AppTheme.Palette.success
            case .nothing: return nil
            }
        default: return nil
        }
    }

    private func renderSelection() {
        valueLabel.text = selectableValue?.title ?? Constants.EMPTY_TEXT
        marker.backgroundColor = Self.markerColor(for: textFieldType, id: selectableValue?.id)
        marker.isHidden = marker.backgroundColor == nil
        accessibilityValue = valueLabel.text
        menu = UIMenu(children: dataSource.map { item in
            UIAction(
                title: item.title,
                image: item.image,
                state: item.id == selectableValue?.id ? .on : .off
            ) { [weak self] _ in
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

private struct Layout {
    static let markerSize: CGFloat = 6
    static let reservedWidth: CGFloat = 28

    static let verticalValueSpacing: CGFloat = 6
    static let markerRadius: CGFloat = 3
    static let chevronWidth: CGFloat = 12
    static let chevronHeight: CGFloat = 16
    static let minimumRowHeight: CGFloat = 52
}
