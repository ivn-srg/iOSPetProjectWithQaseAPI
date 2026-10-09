import UIKit
import SnapKit

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
        card.backgroundColor = AppTheme.Palette.secondarySurface
        card.layer.cornerRadius = 16
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        for (index, row) in rows.enumerated() {
            if index > 0 {
                let divider = UIView()
                divider.backgroundColor = AppTheme.Palette.border
                divider.snp.makeConstraints { $0.height.equalTo(1 / UIScreen.main.scale) }
                stack.addArrangedSubview(divider)
            }
            stack.addArrangedSubview(row)
        }
        addSubview(heading)
        addSubview(card)
        card.addSubview(stack)
        heading.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        card.snp.makeConstraints {
            $0.top.equalTo(heading.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        stack.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.verticalEdges.equalToSuperview().inset(4)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
