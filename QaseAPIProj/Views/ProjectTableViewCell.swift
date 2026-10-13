//
//  ProjectTableViewCell.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import UIKit

class ProjectTableViewCell: UITableViewCell {

    static let cellId = "ProjectTableViewCell"

    // MARK: - UI
    private lazy var leftContainerVw: UIView = {
        let lvw = UIView()
        lvw.translatesAutoresizingMaskIntoConstraints = false
        lvw.backgroundColor = .systemBlue
        lvw.layer.cornerRadius = Layout.stripeRadius
        return lvw
    }()

    private lazy var contentStackVw: UIStackView = {
        let stackVw = UIStackView()
        stackVw.translatesAutoresizingMaskIntoConstraints = false
        stackVw.spacing = Layout.labelSpacing
        stackVw.axis = .vertical
        return stackVw
    }()

    private lazy var nameLbl: UILabel = {
        let nameLbl = UILabel()
        nameLbl.translatesAutoresizingMaskIntoConstraints = false
        nameLbl.font = .preferredFont(forTextStyle: .headline)
        nameLbl.numberOfLines = 0
        nameLbl.adjustsFontForContentSizeCategory = true
        return nameLbl
    }()

    private lazy var codeLbl: UILabel = {
        let cLbl = UILabel()
        cLbl.translatesAutoresizingMaskIntoConstraints = false
        cLbl.font = .preferredFont(forTextStyle: .footnote)
        cLbl.numberOfLines = 0
        cLbl.adjustsFontForContentSizeCategory = true
        cLbl.textColor = .systemGray
        return cLbl
    }()

    private lazy var testsAndSuitesLbl: UILabel = {
        let tLbl = UILabel()
        tLbl.translatesAutoresizingMaskIntoConstraints = false
        tLbl.font = .preferredFont(forTextStyle: .footnote)
        tLbl.numberOfLines = 0
        tLbl.adjustsFontForContentSizeCategory = true
        return tLbl
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - lifecycles

    func configure(with project: Project) {
        let infoAboutActiveRuns: String
        let textForLbl: String

        if let projectCounts = project.counts {
            if let projectTestRuns = projectCounts.runs {
                infoAboutActiveRuns = projectTestRuns.active == 0
                    ? "No active runs".localized
                    : String.localizedStringWithFormat("%lld active runs".localized, projectTestRuns.active)
            } else { infoAboutActiveRuns =  "No active runs".localized }
            textForLbl = [
                String.localizedStringWithFormat("%lld cases".localized, projectCounts.cases),
                String.localizedStringWithFormat("%lld suites".localized, projectCounts.suites),
                infoAboutActiveRuns
            ].joined(separator: " | ")
        } else {
            infoAboutActiveRuns = "No active runs".localized
            textForLbl = ""
        }

        nameLbl.text = project.title
        codeLbl.text = project.code
        testsAndSuitesLbl.text = textForLbl

    }

    private func setupLayout() {
        contentView.backgroundColor = AppTheme.Palette.secondarySurface
        contentView.addSubview(contentStackVw)
        contentView.addSubview(leftContainerVw)

        contentStackVw.addArrangedSubview(nameLbl)
        contentStackVw.addArrangedSubview(codeLbl)
        contentStackVw.addArrangedSubview(testsAndSuitesLbl)

        leftContainerVw.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(Layout.verticalInset)
            $0.leading.equalToSuperview().offset(AppTheme.Space.small)
            $0.width.equalTo(Layout.stripeWidth)
        }
        contentStackVw.snp.makeConstraints {
            $0.verticalEdges.equalTo(leftContainerVw.snp.verticalEdges)
            $0.leading.equalTo(leftContainerVw.snp.trailing).offset(AppTheme.Space.small)
            $0.trailing.equalToSuperview().inset(AppTheme.Space.small)
        }
    }
}

private struct Layout {
    static let verticalInset: CGFloat = 6
    static let labelSpacing: CGFloat = 6
    static let stripeRadius: CGFloat = 2
    static let stripeWidth: CGFloat = 4
}
