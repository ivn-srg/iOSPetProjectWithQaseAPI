//
//  CustomSelectableView.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 30.10.2024.
//

import UIKit

final class CustomSelectableView: UIButton {
    // MARK: - Fields
    private var selectableValue: MenuItem?
    private var dataSource = [MenuItem]()
    private let textFieldType: FieldType
    private var testCaseViewModel: UpdatableEntityProtocol?
    private var fieldValue: MenuItem? {
        guard let testCaseViewModel = testCaseViewModel else { return nil }
        
        switch textFieldType {
        case .severity:
            return testCaseViewModel.testCase?.severity.menuItem
        case .status:
            return testCaseViewModel.testCase?.status.menuItem
        case .priority:
            return testCaseViewModel.testCase?.priority.menuItem
        case .behavior:
            return testCaseViewModel.testCase?.behavior.menuItem
        case .type:
            return testCaseViewModel.testCase?.type.menuItem
        case .layer:
            return testCaseViewModel.testCase?.layer.menuItem
        case .automation:
            return testCaseViewModel.testCase?.automation.menuItem
        default: return nil
        }
    }
    
    // MARK: - UI components
    private lazy var textLbl: UILabel = {
        let text = UILabel()
        text.translatesAutoresizingMaskIntoConstraints = false
        return text
    }()
    
    private lazy var trailingImage: UIImageView = {
        let imageV = UIImageView()
        imageV.translatesAutoresizingMaskIntoConstraints = false
        imageV.contentMode = .scaleAspectFit
        imageV.image = selectableValue?.image
        return imageV
    }()
    
    // MARK: - Lyfecycle
    init(textFieldType: FieldType, detailCaseVM: UpdatableEntityProtocol?) {
        self.textFieldType = textFieldType
        self.testCaseViewModel = detailCaseVM
        super.init(frame: .zero)
        
        setupDataSource(textFieldType)
        configureView()
        setupActionsMenu()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - setup UI funcs
    private func setupDataSource(_ textFieldType: FieldType) {
        let testCase = testCaseViewModel?.testCase
        
        switch textFieldType {
        case .severity:
            dataSource = Severity.dataSource
            selectableValue = testCase != nil ? testCase!.severity.menuItem : MenuItem()
        case .status:
            dataSource = Status.dataSource
            selectableValue = testCase != nil ? testCase!.status.menuItem : MenuItem()
        case .priority:
            dataSource = Priority.dataSource
            selectableValue = testCase != nil ? testCase!.priority.menuItem : MenuItem()
        case .behavior:
            dataSource = Behavior.dataSource
            selectableValue = testCase != nil ? testCase!.behavior.menuItem : MenuItem()
        case .type:
            dataSource = Types.dataSource
            selectableValue = testCase != nil ? testCase!.type.menuItem : MenuItem()
        case .layer:
            dataSource = Layer.dataSource
            selectableValue = testCase != nil ? testCase!.layer.menuItem : MenuItem()
        case .automation:
            dataSource = AutomationStatus.dataSource
            selectableValue = testCase != nil ? testCase!.automation.menuItem : MenuItem()
        default: break
        }
    }
    
    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        
        textLbl.text = fieldValue?.title
        
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor.gray.cgColor
        backgroundColor = AppTheme.bgSecondaryColor
        
        addSubview(textLbl)
        addSubview(trailingImage)
        
        trailingImage.snp.makeConstraints {
            $0.verticalEdges.trailing.equalToSuperview().inset(15)
            $0.width.equalTo(trailingImage.image?.size.width ?? 30)
        }
        
        textLbl.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(15)
            $0.leading.equalToSuperview().inset(15)
            $0.trailing.equalTo(trailingImage.snp.leading)
        }
    }
    
    private func setupActionsMenu() {
        let actionList = dataSource.map { item in
            UIAction(
                title: item.title,
                image: item.image
            ) { action in
                if self.selectableValue == nil {
                    self.selectableValue = MenuItem(
                        id: item.id,
                        title: action.title,
                        image: action.image
                    )
                } else {
                    self.selectableValue?.id = item.id
                    self.selectableValue?.title = action.title
                    self.selectableValue?.image = action.image
                }
                
                self.textLbl.text = action.title
                self.trailingImage.image = action.image
                
                self.updateTestCaseData()
            }
        }
        
        menu = UIMenu(title: "", children: actionList)
        showsMenuAsPrimaryAction = true
    }
    
    func updateTestCaseData() {
        guard let testCaseViewModel else { return }
        let testCase = testCaseViewModel.testCase
        
        switch textFieldType {
        case .severity:
            let selectedValue = if selectableValue != nil {
                selectableValue!
            } else if let testCase = testCase {
                testCase.severity.menuItem
            } else {
                Severity.nothing.menuItem
            }
            
            testCaseViewModel.updateValue(for: .severity, value: selectedValue.id)
        case .status:
            let selectedValue = if selectableValue != nil {
                selectableValue!
            } else if let testCase = testCase {
                testCase.status.menuItem
            } else {
                Status.actual.menuItem
            }
            
            testCaseViewModel.updateValue(for: .status, value: selectedValue.id)
        case .priority:
            let selectedValue = if selectableValue != nil {
                selectableValue!
            } else if let testCase = testCase {
                testCase.priority.menuItem
            } else {
                Priority.nothing.menuItem
            }
            
            testCaseViewModel.updateValue(for: .priority, value: selectedValue.id)
        case .behavior:
            let selectedValue = if selectableValue != nil {
                selectableValue!
            } else if let testCase = testCase {
                testCase.behavior.menuItem
            } else {
                Behavior.positive.menuItem
            }
            
            testCaseViewModel.updateValue(for: .behavior, value: selectedValue.id)
        case .type:
            let selectedValue = if selectableValue != nil {
                selectableValue!
            } else if let testCase = testCase {
                testCase.type.menuItem
            } else {
                Types.other.menuItem
            }
            
            testCaseViewModel.updateValue(for: .type, value: selectedValue.id)
        case .layer:
            let selectedValue = if selectableValue != nil {
                selectableValue!
            } else if let testCase = testCase {
                testCase.layer.menuItem
            } else {
                Layer.e2e.menuItem
            }
            
            testCaseViewModel.updateValue(for: .layer, value: selectedValue.id)
        case .automation:
            let selectedValue = if selectableValue != nil {
                selectableValue!
            } else if let testCase = testCase {
                testCase.automation.menuItem
            } else {
                AutomationStatus.manual.menuItem
            }
            
            testCaseViewModel.updateValue(for: .automation, value: selectedValue.id)
        default: break
        }
    }
    
    func updateSelectedValue() {
        guard let testCaseViewModel else { return }
        
        switch textFieldType {
        case .severity:
            selectableValue = testCaseViewModel.testCase?.severity.menuItem
        case .status:
            selectableValue = testCaseViewModel.testCase?.status.menuItem
        case .priority:
            selectableValue = testCaseViewModel.testCase?.priority.menuItem
        case .behavior:
            selectableValue = testCaseViewModel.testCase?.behavior.menuItem
        case .type:
            selectableValue = testCaseViewModel.testCase?.type.menuItem
        case .layer:
            selectableValue = testCaseViewModel.testCase?.layer.menuItem
        case .automation:
            selectableValue = testCaseViewModel.testCase?.automation.menuItem
        default: break
        }
    }
}
