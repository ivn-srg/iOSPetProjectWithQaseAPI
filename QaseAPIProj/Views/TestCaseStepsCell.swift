//
//  TestCaseStepsCell.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 06.01.2025.
//

import UIKit

final class StepCell: UICollectionViewCell {
    // MARK: - Fields
    static let identifier = "StepCell"
    
    var stepHash = ""
    
    // MARK: - UI components
    private lazy var digitalInBoxLbl: PaddedLabel = {
        let view = PaddedLabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = AppTheme.additionTintColor
        view.layer.masksToBounds = true
        view.textInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        view.layer.cornerRadius = 8
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        return view
    }()
    
    
    private lazy var titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = .systemFont(ofSize: 14, weight: .regular)
        lbl.numberOfLines = 2
        return lbl
    }()
    
    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        contentView.addSubview(digitalInBoxLbl)
        contentView.addSubview(titleLabel)
        
        digitalInBoxLbl.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(10)
            $0.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(digitalInBoxLbl.snp.trailing).offset(10)
            $0.verticalEdges.trailing.equalToSuperview().inset(10)
        }
    }
    
    func configure(with step: StepsInTestCase, at index: Int) {
        digitalInBoxLbl.text = "\(index + 1)"
        stepHash = step.hash
        if let attributedString = step.action?.withoutLineBreaks.toAttributedString() {
            titleLabel.attributedText = attributedString
        } else {
            titleLabel.text = step.action
        }
    }
}

final class PaddedLabel: UILabel {
    
    var textInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

    override func drawText(in rect: CGRect) {
        let insetsRect = rect.inset(by: textInsets)
        super.drawText(in: insetsRect)
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        let width = size.width + textInsets.left + textInsets.right
        let height = size.height + textInsets.top + textInsets.bottom
        return CGSize(width: width, height: height)
    }
}
