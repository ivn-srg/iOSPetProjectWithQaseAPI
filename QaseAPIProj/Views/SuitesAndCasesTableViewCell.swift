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
    
    func configure(with dataForCell: TestListEntity) {
        if !dataForCell.isSuite {
            var image: UIImage? = .init()
            var color: UIColor = .init()
            
            switch dataForCell.priority {
            case .high:
                image = AppTheme.chevronUpImage
                color = .systemRed
            case .medium:
                image = AppTheme.circleImage
                color = .systemGray
            case .low:
                image = AppTheme.chevronDownImage
                color = .systemGreen
            default:
                image = AppTheme.minusImage
                color = .systemGray
            }
            
            priorityImage.image = image
            priorityImage.tintColor = color
            
            
            switch dataForCell.automation {
            case .toBeAutomated:
                image = AppTheme.personWithGearshapeImage
                color = .systemGray
            case .automation:
                image = AppTheme.gearshapeFillImage
                color = .systemBlue
            default:
                image = AppTheme.handRaisedImage
                color = .systemGray
            }
            
            automationImage.image = image
            automationImage.tintColor = color
        } else {
            accessoryType = .disclosureIndicator
        }
        
        titleLbl.text = dataForCell.title
        descriptionLbl.text = dataForCell.itemDescription?.replacingOccurrences(of: "\n", with: " ")
        
        contentView.addSubview(priorityImage)
        priorityImage.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview().offset(!dataForCell.isSuite ? 10 : 0)
            $0.width.equalTo(!dataForCell.isSuite ? 20 : 0)
        }
        
        contentView.addSubview(automationImage)
        automationImage.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalTo(priorityImage.snp.trailing).offset(!dataForCell.isSuite ? 10 : 0)
            $0.width.equalTo(!dataForCell.isSuite ? 20 : 0)
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
        
        priorityImage.snp.removeConstraints()
        automationImage.snp.removeConstraints()
        contentStackVw.snp.removeConstraints()
    }
}
