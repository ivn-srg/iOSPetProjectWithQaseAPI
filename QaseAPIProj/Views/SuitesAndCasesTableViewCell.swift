//
//  SuitesAndCasesTableViewCell.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 13.01.2024.
//

import UIKit

class SuitesAndCasesTableViewCell: UITableViewCell {
    
    static let cellId = "SuitesAndCasesTableViewCell"
    
    // MARK: - UI
    
    private lazy var containerVw: UIView = {
        let vw = UIView()
        vw.translatesAutoresizingMaskIntoConstraints = false
        return vw
    }()
    
    private lazy var priorityImage: UIImageView = {
        let piv = UIImageView()
        piv.translatesAutoresizingMaskIntoConstraints = false
        return piv
    }()
    
    private lazy var automationImage: UIImageView = {
        let aiv = UIImageView()
        aiv.translatesAutoresizingMaskIntoConstraints = false
        return aiv
    }()
    
    private lazy var contentStackVw: UIStackView = {
        let stackVw = UIStackView()
        stackVw.translatesAutoresizingMaskIntoConstraints = false
        stackVw.spacing = 6
        stackVw.axis = .vertical
        return stackVw
    }()
    
    private lazy var titleLbl: UILabel = {
        let nameLbl = UILabel()
        nameLbl.translatesAutoresizingMaskIntoConstraints = false
        nameLbl.font = .systemFont(ofSize: 18, weight: .bold)
        nameLbl.numberOfLines = 0
        nameLbl.textColor = .black
        return nameLbl
    }()
    
    private lazy var descriptionLbl: UILabel = {
        let cLbl = UILabel()
        cLbl.translatesAutoresizingMaskIntoConstraints = false
        cLbl.font = .systemFont(ofSize: 12, weight: .regular)
        cLbl.numberOfLines = 0
        cLbl.textColor = .systemGray
        return cLbl
    }()
    
    private lazy var deepIcon: UIImageView = {
        let tLbl = UIImageView()
        tLbl.translatesAutoresizingMaskIntoConstraints = false
        return tLbl
    }()
    
    // MARK: - lifecycles
    
    func configure(with project: Project) {
        let infoAboutActiveRuns = project.counts.runs.active == 0 ? "No active runs" : "\(project.counts.runs.active) active run(s)"
        
        containerVw.backgroundColor = .white
        
//        nameLbl.text = project.title
//        codeLbl.text = project.code
//        testsAndSuitesLbl.text = "\(project.counts.cases) cases | \(project.counts.suites) suites | \(infoAboutActiveRuns)"
//        
//        self.contentView.addSubview(containerVw)
//        
//        containerVw.addSubview(contentStackVw)
//        containerVw.addSubview(leftContainerVw)
//        
//        contentStackVw.addArrangedSubview(nameLbl)
//        contentStackVw.addArrangedSubview(codeLbl)
//        contentStackVw.addArrangedSubview(testsAndSuitesLbl)
//        
//        NSLayoutConstraint.activate([
//            containerVw.topAnchor.constraint(equalTo: self.contentView.topAnchor),
//            containerVw.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
//            containerVw.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
//            containerVw.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
//            
//            leftContainerVw.topAnchor.constraint(equalTo: containerVw.topAnchor, constant: 6),
//            leftContainerVw.bottomAnchor.constraint(equalTo: containerVw.bottomAnchor, constant: -6),
//            leftContainerVw.leadingAnchor.constraint(equalTo: containerVw.leadingAnchor, constant: 8),
//            leftContainerVw.widthAnchor.constraint(equalToConstant: 4),
//            
//            contentStackVw.topAnchor.constraint(equalTo: self.leftContainerVw.topAnchor),
//            contentStackVw.bottomAnchor.constraint(equalTo: self.leftContainerVw.bottomAnchor),
//            contentStackVw.leadingAnchor.constraint(equalTo: self.leftContainerVw.trailingAnchor, constant: 6),
//            contentStackVw.trailingAnchor.constraint(equalTo: self.containerVw.trailingAnchor, constant: -8),
//            
//        ])
    }
    
}

