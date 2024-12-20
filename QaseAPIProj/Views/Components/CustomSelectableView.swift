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
    private let textFieldType: PropertiesCaseTextFieldTypes
    private var testCaseViewModel: DetailTabbarControllerViewModel?
    private var originalIntValue: Int? {
        guard let testCaseViewModel = testCaseViewModel else { return nil }
        
        switch textFieldType {
        case .severity:
            return testCaseViewModel.testCase?.severity
        case .status:
            return testCaseViewModel.testCase?.status
        case .priority:
            return testCaseViewModel.testCase?.priority
        case .behavior:
            return testCaseViewModel.testCase?.behavior
        case .type:
            return testCaseViewModel.testCase?.type
        case .layer:
            return testCaseViewModel.testCase?.layer
        case .automationStatus:
            return testCaseViewModel.testCase?.automation
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
    init(
        textFieldType: PropertiesCaseTextFieldTypes,
        detailCaseVM: DetailTabbarControllerViewModel?
    ) {
        self.textFieldType = textFieldType
        self.testCaseViewModel = detailCaseVM
        super.init(frame: .zero)
        
        let testCase = testCaseViewModel?.testCase
        
        switch textFieldType {
        case .severity:
            self.dataSource = Severity.dataSource
            self.selectableValue = convertIntValueToMenuItem(testCase != nil ? testCase!.severity : 0)
        case .status:
            self.dataSource = Status.dataSource
            self.selectableValue = convertIntValueToMenuItem(testCase != nil ? testCase!.status : 0)
        case .priority:
            self.dataSource = Priority.dataSource
            self.selectableValue = convertIntValueToMenuItem(testCase != nil ? testCase!.priority : 0)
        case .behavior:
            self.dataSource = Behavior.dataSource
            self.selectableValue = convertIntValueToMenuItem(testCase != nil ? testCase!.behavior : 0)
        case .type:
            self.dataSource = Types.dataSource
            self.selectableValue = convertIntValueToMenuItem(testCase != nil ? testCase!.type : 0)
        case .layer:
            self.dataSource = Layer.dataSource
            self.selectableValue = convertIntValueToMenuItem(testCase != nil ? testCase!.layer : 0)
        case .automationStatus:
            self.dataSource = AutomationStatus.dataSource
            self.selectableValue = convertIntValueToMenuItem(testCase != nil ? testCase!.automation : 0)
        }
        
        configureView()
        
        let actionList = dataSource.map {
            UIAction(
                title: $0.title,
                image: $0.image,
                handler: handleMenuItemTapped
            )
        }
        menu = UIMenu(title: "", children: actionList)
        showsMenuAsPrimaryAction = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        translatesAutoresizingMaskIntoConstraints = false
        
        textLbl.text = convertIntValueToMenuItem(originalIntValue ?? 0)?.title
        
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
    
    private func convertIntValueToMenuItem(_ value: Int?) -> MenuItem? {
        guard let value = value else { return nil }
        
        switch textFieldType {
        case .severity:
            return Severity.dataSource.first(where: { $0.id == value })
        case .status:
            return Status.dataSource.first(where: { $0.id == value })
        case .priority:
            return Priority.dataSource.first(where: { $0.id == value })
        case .behavior:
            return Behavior.dataSource.first(where: { $0.id == value })
        case .type:
            return Types.dataSource.first(where: { $0.id == value })
        case .layer:
            return Layer.dataSource.first(where: { $0.id == value })
        case .automationStatus:
            return AutomationStatus.dataSource.first(where: { $0.id == value })
        }
    }
    
    private func handleMenuItemTapped(_ action: UIAction) {
        selectableValue?.id = Int(action.identifier.rawValue) ?? 0
        selectableValue?.title = action.title
        selectableValue?.image = action.image
        
        textLbl.text = action.title
        trailingImage.image = action.image
        
        updateTestCaseData()
    }
    
    func updateTestCaseData() {
        guard let testCaseViewModel = testCaseViewModel,
              let testCase = testCaseViewModel.changedTestCase
        else { return }
        
        switch textFieldType {
        case .severity:
            testCaseViewModel.changedTestCase?.severity = selectableValue?.id ?? testCase.severity
        case .status:
            testCaseViewModel.changedTestCase?.status = selectableValue?.id ?? testCase.status
        case .priority:
            testCaseViewModel.changedTestCase?.priority = selectableValue?.id ?? testCase.priority
        case .behavior:
            testCaseViewModel.changedTestCase?.behavior = selectableValue?.id ?? testCase.behavior
        case .type:
            testCaseViewModel.changedTestCase?.type = selectableValue?.id ?? testCase.type
        case .layer:
            testCaseViewModel.changedTestCase?.layer = selectableValue?.id ?? testCase.layer
        case .automationStatus:
            testCaseViewModel.changedTestCase?.automation = selectableValue?.id ?? testCase.automation
        }
    }
    
    func updateSelectedValue() {
        guard let testCaseViewModel = testCaseViewModel else { return }
        
        switch textFieldType {
        case .severity:
            selectableValue = convertIntValueToMenuItem(testCaseViewModel.testCase?.severity)
        case .status:
            selectableValue = convertIntValueToMenuItem(testCaseViewModel.testCase?.status)
        case .priority:
            selectableValue = convertIntValueToMenuItem(testCaseViewModel.testCase?.priority)
        case .behavior:
            selectableValue = convertIntValueToMenuItem(testCaseViewModel.testCase?.behavior)
        case .type:
            selectableValue = convertIntValueToMenuItem(testCaseViewModel.testCase?.type)
        case .layer:
            selectableValue = convertIntValueToMenuItem(testCaseViewModel.testCase?.layer)
        case .automationStatus:
            selectableValue = convertIntValueToMenuItem(testCaseViewModel.testCase?.automation)
        }
    }
}
