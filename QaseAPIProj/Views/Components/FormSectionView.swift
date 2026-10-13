import SnapKit
import UIKit

final class FormSectionView: UIView {
    init(title: String, rows: [UIView]) {
        super.init(frame: .zero)
        let heading = UILabel()
        heading.text = title
        heading.font = UIFont.preferredFont(forTextStyle: .headline)
        heading.adjustsFontForContentSizeCategory = true
        heading.numberOfLines = 0
        heading.textColor = AppTheme.Palette.secondaryText
        heading.accessibilityTraits.insert(.header)
        let card = UIView()
        card.backgroundColor = AppTheme.Palette.surface
        card.layer.cornerRadius = AppTheme.Radius.card
        let stack = UIStackView()
        stack.axis = .vertical
        let textRows = rows.contains { $0 is GeneralCaseTextField }
        stack.spacing = textRows ? AppTheme.Space.regular : 0
        stack.alignment = .fill
        for (index, row) in rows.enumerated() {
            if index > 0 && !textRows {
                let divider = UIView()
                divider.backgroundColor = AppTheme.Palette.border
                divider.snp.makeConstraints { $0.height.equalTo(1 / traitCollection.displayScale) }
                stack.addArrangedSubview(divider)
            }
            stack.addArrangedSubview(row)
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
            $0.verticalEdges.equalToSuperview().inset(textRows ? AppTheme.Space.regular : AppTheme.Space.tiny)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
