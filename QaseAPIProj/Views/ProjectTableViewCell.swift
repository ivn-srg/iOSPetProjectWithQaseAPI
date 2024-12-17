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
        lvw.layer.cornerRadius = 2
        return lvw
    }()
    
    private lazy var contentStackVw: UIStackView = {
        let stackVw = UIStackView()
        stackVw.translatesAutoresizingMaskIntoConstraints = false
        stackVw.spacing = 6
        stackVw.axis = .vertical
        return stackVw
    }()
    
    private lazy var nameLbl: UILabel = {
        let nameLbl = UILabel()
        nameLbl.translatesAutoresizingMaskIntoConstraints = false
        nameLbl.font = .systemFont(ofSize: 18, weight: .bold)
        nameLbl.numberOfLines = 0
        return nameLbl
    }()
    
    private lazy var codeLbl: UILabel = {
        let cLbl = UILabel()
        cLbl.translatesAutoresizingMaskIntoConstraints = false
        cLbl.font = .systemFont(ofSize: 12, weight: .regular)
        cLbl.numberOfLines = 0
        cLbl.textColor = .systemGray
        return cLbl
    }()
    
    private lazy var testsAndSuitesLbl: UILabel = {
        let tLbl = UILabel()
        tLbl.translatesAutoresizingMaskIntoConstraints = false
        tLbl.font = .systemFont(ofSize: 12, weight: .regular)
        tLbl.numberOfLines = 0
        return tLbl
    }()
    
    // MARK: - lifecycles
    
    func configure(with project: Project) {
        let infoAboutActiveRuns: String
        let textForLbl: String
        
        if let projectCounts = project.counts {
            if let projectTestRuns = projectCounts.runs {
                infoAboutActiveRuns = projectTestRuns.active == 0
                ? "No active runs"
                : "\(projectTestRuns.active) active run(s)"
            } else { infoAboutActiveRuns =  "No active runs" }
            textForLbl = "\(projectCounts.cases) cases | \(projectCounts.suites) suites | \(infoAboutActiveRuns)"
        } else {
            infoAboutActiveRuns = "No active runs"
            textForLbl = ""
        }
        
        nameLbl.text = project.title
        codeLbl.text = project.code
        testsAndSuitesLbl.text = textForLbl
        
        contentView.backgroundColor = AppTheme.bgSecondaryColor
        contentView.addSubview(contentStackVw)
        contentView.addSubview(leftContainerVw)
        
        contentStackVw.addArrangedSubview(nameLbl)
        contentStackVw.addArrangedSubview(codeLbl)
        contentStackVw.addArrangedSubview(testsAndSuitesLbl)
        
        leftContainerVw.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(6)
            $0.leading.equalToSuperview().offset(8)
            $0.width.equalTo(4)
        }
        contentStackVw.snp.makeConstraints {
            $0.verticalEdges.equalTo(leftContainerVw.snp.verticalEdges)
            $0.leading.equalTo(leftContainerVw.snp.trailing).offset(8)
            $0.trailing.equalToSuperview().inset(8)
        }
    }
}
