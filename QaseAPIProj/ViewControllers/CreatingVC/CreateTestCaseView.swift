//
//  CreateTestCaseView.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 21.09.2024.
//

import UIKit
import SnapKit

enum CreateCaseTextFieldType: String {
    case title = "Title"
    case description = "Description"
    case preconditions = "Preconditions"
    case postconditions = "Postconditions"
    case severity = "Severity"
    case priority = "Priority"
    case type = "Type"
    case layer = "Layer"
    case isFlaky = "Is Flaky"
    case behavior = "Behavior"
    case automation = "Automation"
    case status = "Status"
    case suiteId = "Suite"
    case attachments = "Attachments"
    case steps = "Steps"
    case tags = "Tags"
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
        sv.isUserInteractionEnabled = true
        return sv
    }()
    
    private lazy var stackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 30
        sv.alignment = .fill
        sv.isUserInteractionEnabled = true
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
        let emptyLabel = UILabel()
        emptyLabel.text = "Empty test uiview"
        emptyLabel.font = .systemFont(ofSize: 20)
        
        self.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(30)
            $0.centerX.width.equalToSuperview()
        }
        stackView.addArrangedSubview(emptyLabel)
    }
}
