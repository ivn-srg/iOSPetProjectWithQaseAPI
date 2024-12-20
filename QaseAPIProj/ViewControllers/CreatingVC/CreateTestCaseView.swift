//
//  CreateTestCaseView.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 21.09.2024.
//

import UIKit
import SnapKit

enum CreateCaseTextFieldType: String, CaseIterable {
    case title = "Title"
    case description = "Description"
    case preconditions = "Precondition"
    case postconditions = "Postcondition"
    case severity = "Severity"
    case priority = "Priority"
    case type = "Type"
    case layer = "Layer"
    case isFlaky = "Is Flaky"
    case behavior = "Behavior"
    case automation = "Automation status"
    case status = "Status"
    case suiteId = "Parent suite"
//    case attachments = "Attachments"
//    case steps = "Steps"
//    case tags = "Tags"
}

final class CreateTestCaseView: UIView {
    // MARK: - Fields
    private var linkedViewModel: CreateSuiteOrCaseViewModel
    
    // MARK: - UI components
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsHorizontalScrollIndicator = false
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    private lazy var stackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 30
        sv.alignment = .fill
        return sv
    }()
    
    // MARK: - Lyfecycle
    init(linkedViewModel: CreateSuiteOrCaseViewModel) {
        self.linkedViewModel = linkedViewModel
        super.init(frame: .zero)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureView() {
        self.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(30)
            $0.centerX.width.equalToSuperview()
        }
        
        CreateCaseTextFieldType.allCases.forEach {
            switch $0 {
            case .title, .description, .preconditions, .postconditions, .suiteId:
                guard let textFieldType = GeneralCaseTextFieldTypes(rawValue: $0.rawValue) else { return }
                let textField = GeneralCaseTextField(textType: textFieldType, detailVM: linkedViewModel)
                stackView.addArrangedSubview(textField)
            case .severity, .status, .priority, .behavior, .type, .layer, .automation:
                guard let menuFieldType = PropertiesCaseTextFieldTypes(rawValue: $0.rawValue) else { return }
                let menuField = PropertiesPickerTextField(textType: menuFieldType, detailCaseVM: nil)
                stackView.addArrangedSubview(menuField)
            case .isFlaky:
                let switcher = SwitcherWithTitle(title: "Is Flaky".localized, testCaseVM: nil)
                stackView.addArrangedSubview(switcher)
                switcher.snp.makeConstraints {
                    $0.height.equalTo(40)
                }
            }
        }
    }
}
