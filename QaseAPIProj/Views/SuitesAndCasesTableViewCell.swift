//
//  SuitesAndCasesTableViewCell.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 13.01.2024.
//

import UIKit

final class SuitesAndCasesTableViewCell: UITableViewCell {
    
    static let cellId = "SuitesAndCasesTableViewCell"
    
    // MARK: - UI
    
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
        stackVw.axis = .vertical
        stackVw.alignment = .fill
        stackVw.spacing = 3
        return stackVw
    }()
    
    private lazy var titleLbl: UILabel = {
        let nameLbl = UILabel()
        nameLbl.translatesAutoresizingMaskIntoConstraints = false
        nameLbl.font = .systemFont(ofSize: 14, weight: .bold)
        nameLbl.numberOfLines = 2
        nameLbl.textColor = .black
        return nameLbl
    }()
    
    private lazy var descriptionLbl: UILabel = {
        let cLbl = UILabel()
        cLbl.translatesAutoresizingMaskIntoConstraints = false
        cLbl.font = .systemFont(ofSize: 12, weight: .regular)
        cLbl.numberOfLines = 2
        cLbl.textColor = .systemGray
        return cLbl
    }()
    
    // MARK: - lifecycles
    
    func configure(with dataForCell: SuiteAndCaseData) {
        if !dataForCell.isSuites {
            switch dataForCell.priority {
                case 1:
                    priorityImage.image = AppTheme.highPriorityImage
                    priorityImage.tintColor = .systemRed
                case 2:
                    priorityImage.image = AppTheme.mediumPriorityImage
                    priorityImage.tintColor = .systemGray
                case 3:
                    priorityImage.image = AppTheme.lowPriorityImage
                    priorityImage.tintColor = .systemGreen
                default:
                    priorityImage.image = AppTheme.noPriorityImage
                    priorityImage.tintColor = .systemGray
            }
            
            switch dataForCell.automation {
                case 1:
                    automationImage.image = AppTheme.toBeAutomationImage
                    automationImage.tintColor = .systemGray
                case 2:
                    automationImage.image = AppTheme.automationImage
                    automationImage.tintColor = .systemBlue
                default:
                    automationImage.image = AppTheme.notAutomationImage
                    automationImage.tintColor = .systemGray
            }
        } else {
            accessoryType = .disclosureIndicator
        }
                
        titleLbl.text = dataForCell.title
        descriptionLbl.text = dataForCell.itemDescription?.replacingOccurrences(of: "\n", with: " ")
        
        contentView.addSubview(priorityImage)
        priorityImage.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(!dataForCell.isSuites ? 10 : 0)
            $0.width.equalTo(!dataForCell.isSuites ? 20 : 0)
        }
        contentView.addSubview(automationImage)
        automationImage.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalTo(priorityImage.snp.trailing).offset(!dataForCell.isSuites ? 10 : 0)
            $0.width.equalTo(!dataForCell.isSuites ? 20 : 0)
        }
        contentView.addSubview(contentStackVw)
        contentStackVw.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(8)
            $0.leading.equalTo(automationImage.snp.trailing).offset(15)
            $0.trailing.equalToSuperview().inset(50)
        }
        
        contentStackVw.addArrangedSubview(titleLbl)
        contentStackVw.addArrangedSubview(descriptionLbl)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        accessoryType = .none
        titleLbl.text = ""
        descriptionLbl.text = ""
        priorityImage.image = nil
        automationImage.image = nil
    }
}
