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
    
    private lazy var containerVw: UIView = {
        let vw = UIView()
        vw.translatesAutoresizingMaskIntoConstraints = false
        return vw
    }()
    
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
        nameLbl.textColor = .black
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
        tLbl.textColor = .black
        return tLbl
    }()
    
    // MARK: - lifecycles
    
    func configure(with project: Project) {
        let infoAboutActiveRuns = project.counts.runs.active == 0 ? "No active runs" : "\(project.counts.runs.active) active run(s)"
        
        nameLbl.text = project.title
        codeLbl.text = project.code
        testsAndSuitesLbl.text = "\(project.counts.cases) cases | \(project.counts.suites) suites | \(infoAboutActiveRuns)"
        
        self.contentView.addSubview(containerVw)
        
        containerVw.addSubview(contentStackVw)
        containerVw.addSubview(leftContainerVw)
        
        contentStackVw.addArrangedSubview(nameLbl)
        contentStackVw.addArrangedSubview(codeLbl)
        contentStackVw.addArrangedSubview(testsAndSuitesLbl)
        
        containerVw.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
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
