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
        piv.contentMode = .scaleAspectFit
        return piv
    }()
    
    private lazy var automationImage: UIImageView = {
        let aiv = UIImageView()
        aiv.translatesAutoresizingMaskIntoConstraints = false
        aiv.contentMode = .scaleAspectFit
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
        nameLbl.font = .systemFont(ofSize: 15, weight: .bold)
        nameLbl.numberOfLines = 2
        nameLbl.textColor = .black
        return nameLbl
    }()
    
    private lazy var descriptionLbl: UILabel = {
        let cLbl = UILabel()
        cLbl.translatesAutoresizingMaskIntoConstraints = false
        cLbl.font = .systemFont(ofSize: 12, weight: .regular)
        cLbl.numberOfLines = 3
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
            priorityImage.tintColor = .systemRed
        case 2:
            priorityImage.image = Constants.mediumPriorityImage
            priorityImage.tintColor = .systemGray
        case 3:
            priorityImage.image = Constants.lowPriorityImage
            priorityImage.tintColor = .systemGreen
        default:
            priorityImage.image = nil
        }
        
        switch testCase.automation {
        case 0:
            automationImage.image = Constants.notAutomationImage
            automationImage.tintColor = .systemGray
        case 1:
            automationImage.image = Constants.toBeAutomationImage
            automationImage.tintColor = .systemGray
        case 2:
            automationImage.image = Constants.automationImage
            automationImage.tintColor = .systemBlue
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
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            containerVw.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            containerVw.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            containerVw.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            containerVw.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            
            priorityImage.centerYAnchor.constraint(equalTo: containerVw.centerYAnchor),
            priorityImage.leadingAnchor.constraint(equalTo: containerVw.leadingAnchor, constant: priorityImage.image != nil ? 10 : 0),
            priorityImage.widthAnchor.constraint(equalToConstant: priorityImage.image != nil ? 40 : 0),
            
            automationImage.centerYAnchor.constraint(equalTo: containerVw.centerYAnchor),
            automationImage.leadingAnchor.constraint(equalTo: priorityImage.trailingAnchor),
            automationImage.widthAnchor.constraint(equalToConstant: 40),
            
            contentStackVw.topAnchor.constraint(equalTo: self.containerVw.topAnchor, constant: 8),
            contentStackVw.bottomAnchor.constraint(equalTo: self.containerVw.bottomAnchor, constant: 8),
            contentStackVw.leadingAnchor.constraint(equalTo: self.automationImage.trailingAnchor, constant: 6),
            contentStackVw.trailingAnchor.constraint(equalTo: self.containerVw.trailingAnchor, constant: -30),
            
            titleLbl.topAnchor.constraint(equalTo: contentStackVw.topAnchor),
            titleLbl.leadingAnchor.constraint(equalTo: contentStackVw.leadingAnchor),
            titleLbl.trailingAnchor.constraint(equalTo: contentStackVw.trailingAnchor),
            
            descriptionLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor),
            descriptionLbl.leadingAnchor.constraint(equalTo: contentStackVw.leadingAnchor),
            descriptionLbl.trailingAnchor.constraint(equalTo: contentStackVw.trailingAnchor),
            descriptionLbl.bottomAnchor.constraint(equalTo: contentStackVw.bottomAnchor),
            
        ])
    }
    
}
