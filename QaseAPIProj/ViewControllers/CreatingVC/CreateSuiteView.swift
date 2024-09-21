//
//  CreateSuiteView.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 21.09.2024.
//

import UIKit
import SnapKit

enum CreateSuiteTextFieldType: String {
    case name = "Title"
    case description = "Description"
    case precondition = "Preconditions"
    case parentSuteId = "Parent suite"
}

final class CreateSuiteView: UIView {
    // MARK: - Fields
    private var linkedViewModel: CreateSuiteOrCaseViewModel
    private var textViewHeightConstraint: Constraint?
    
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
        sv.backgroundColor = .white
        sv.axis = .vertical
        sv.spacing = 30
        sv.alignment = .fill
        sv.isUserInteractionEnabled = true
        return sv
    }()
    
    private lazy var titleTextView = GeneralCaseTextField(textType: .name, detailVM: linkedViewModel)
    private lazy var descriptionTextView = GeneralCaseTextField(textType: .description, detailVM: linkedViewModel)
    private lazy var preconditionsTextView = GeneralCaseTextField(textType: .precondition, detailVM: linkedViewModel)
    private lazy var parentSuiteTextView = GeneralCaseTextField(textType: .parentSuite, detailVM: linkedViewModel)
    
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
        self.backgroundColor = .white
        
        self.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(30)
            $0.centerX.width.equalToSuperview()
        }
        stackView.addArrangedSubview(titleTextView)
        stackView.addArrangedSubview(descriptionTextView)
        stackView.addArrangedSubview(preconditionsTextView)
        stackView.addArrangedSubview(parentSuiteTextView)
    }
}
