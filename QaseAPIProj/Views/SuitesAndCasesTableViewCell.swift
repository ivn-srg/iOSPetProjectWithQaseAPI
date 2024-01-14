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
    
    func configure(with testCase: TestEntity) {
        
        containerVw.backgroundColor = .white
        
        switch testCase.priority {
        case 1:
            priorityImage.image = Constants.highPriorityImage
        case 2:
            priorityImage.image = Constants.mediumPriorityImage
        case 3:
            priorityImage.image = Constants.lowPriorityImage
        default:
            priorityImage.image = nil
        }
        
        switch testCase.automation {
        case 0:
            automationImage.image = Constants.notAutomationImage
        case 1:
            automationImage.image = Constants.toBeAutomationImage
        case 2:
            automationImage.image = Constants.automationImage
        default:
            automationImage.image = nil
        }
        
        titleLbl.text = testCase.title
        descriptionLbl.text = testCase.description
        
        self.contentView.addSubview(containerVw)
        
        containerVw.addSubview(priorityImage)
        containerVw.addSubview(automationImage)
        containerVw.addSubview(contentStackVw)
        
        contentStackVw.addArrangedSubview(titleLbl)
        contentStackVw.addArrangedSubview(descriptionLbl)
        
        NSLayoutConstraint.activate([
            containerVw.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            containerVw.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            containerVw.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            containerVw.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            
            priorityImage.centerYAnchor.constraint(equalTo: containerVw.centerYAnchor),
            priorityImage.leadingAnchor.constraint(equalTo: containerVw.leadingAnchor, constant: 12),
            
            automationImage.centerYAnchor.constraint(equalTo: containerVw.centerYAnchor),
            automationImage.leadingAnchor.constraint(equalTo: priorityImage.leadingAnchor, constant: 12),
            
            contentStackVw.topAnchor.constraint(equalTo: self.containerVw.topAnchor),
            contentStackVw.bottomAnchor.constraint(equalTo: self.containerVw.bottomAnchor),
            contentStackVw.leadingAnchor.constraint(equalTo: self.automationImage.trailingAnchor, constant: 6),
            contentStackVw.trailingAnchor.constraint(equalTo: self.containerVw.trailingAnchor, constant: -30),
            
        ])
    }
    
}
