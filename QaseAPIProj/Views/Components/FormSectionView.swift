import SnapKit
import UIKit

enum FormSectionStyle: Equatable, Sendable {
    case standard
    case grouped
}

final class FormSectionView: UIView {
    init(title: String, rows: [UIView], style: FormSectionStyle = .standard) {
        super.init(frame: .zero)
        let heading = UILabel()
        heading.text = title
        heading.font = UIFont.preferredFont(forTextStyle: .headline)
        heading.adjustsFontForContentSizeCategory = true
        heading.numberOfLines = 0
        heading.textColor = AppTheme.Palette.secondaryText
        heading.accessibilityTraits.insert(.header)
        let card = UIView()
        card.backgroundColor = style == .grouped
            ? AppTheme.Palette.secondarySurface
            : AppTheme.Palette.surface
        card.layer.cornerRadius = AppTheme.Radius.card
        let stack = UIStackView()
        stack.axis = .vertical
        let textRows = rows.contains { $0 is GeneralCaseTextField }
        stack.spacing = style == .standard && textRows ? AppTheme.Space.regular : 0
        stack.alignment = .fill
        for (index, row) in rows.enumerated() {
            if index > 0 && (style == .grouped || !textRows) {
                let divider = UIView()
                divider.backgroundColor = AppTheme.Palette.border
                divider.snp.makeConstraints { $0.height.equalTo(1 / traitCollection.displayScale) }
                stack.addArrangedSubview(divider)
            }
            if style == .grouped, row is GeneralCaseTextField {
                let container = UIView()
                container.addSubview(row)
                row.snp.makeConstraints {
                    $0.horizontalEdges.equalToSuperview()
                    $0.verticalEdges.equalToSuperview().inset(AppTheme.Space.medium)
                }
                stack.addArrangedSubview(container)
            } else {
                stack.addArrangedSubview(row)
            }
        }
        addSubview(heading)
        addSubview(card)
        card.addSubview(stack)
        heading.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        card.snp.makeConstraints {
            $0.top.equalTo(heading.snp.bottom).offset(AppTheme.Space.small)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        stack.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(AppTheme.Space.regular)
            let verticalInset: CGFloat
            if style == .grouped { verticalInset = 0 }
            else { verticalInset = textRows ? AppTheme.Space.regular : AppTheme.Space.tiny }
            $0.verticalEdges.equalToSuperview().inset(verticalInset)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
