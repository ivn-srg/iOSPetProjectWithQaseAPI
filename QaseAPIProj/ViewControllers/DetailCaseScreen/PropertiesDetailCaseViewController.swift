//
//  PropertiesDetailCaseViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit

class PropertiesDetailCaseViewController: UIViewController, UITextFieldDelegate {
    
    let vm: DetailTabbarControllerViewModel
    
    // MARK: - UI
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
    
    private lazy var severityField = PropertiesPickerTextField(
        textType: .severity,
        textFieldValue: self.vm.testCase?.severity ?? 0
    )
    
    private lazy var statusField = PropertiesPickerTextField(
        textType: .status,
        textFieldValue: self.vm.testCase?.status ?? 0
    )
    
    private lazy var priorityField = PropertiesPickerTextField(
        textType: .priority,
        textFieldValue: self.vm.testCase?.priority ?? 0
    )
    
    private lazy var behaviorField = PropertiesPickerTextField(
        textType: .behavior,
        textFieldValue: self.vm.testCase?.behavior ?? 0
    )
    
    private lazy var typeField = PropertiesPickerTextField(
        textType: .type,
        textFieldValue: self.vm.testCase?.type ?? 0
    )
    
    private lazy var layerField: PropertiesPickerTextField = PropertiesPickerTextField(
        textType: .layer,
        textFieldValue: self.vm.testCase?.layer ?? 0
    )
    
    private lazy var automationStatusField: PropertiesPickerTextField = PropertiesPickerTextField(
        textType: .automationStatus,
        textFieldValue: self.vm.testCase?.automation ?? 0
    )
    
    // MARK: - Lifecycles
    
    init(vm: DetailTabbarControllerViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    private func setupView() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide.snp.edges)
        }
        
        stackView.snp.makeConstraints {
            $0.verticalEdges.equalTo(scrollView.snp.verticalEdges).inset(30)
            $0.centerX.equalTo(scrollView.snp.centerX)
            $0.width.equalTo(scrollView.snp.width).inset(30)
        }
        stackView.addArrangedSubview(severityField)
        stackView.addArrangedSubview(statusField)
        stackView.addArrangedSubview(priorityField)
        stackView.addArrangedSubview(behaviorField)
        stackView.addArrangedSubview(typeField)
        stackView.addArrangedSubview(layerField)
        stackView.addArrangedSubview(automationStatusField)
    }
}

extension PropertiesDetailCaseViewController: UpdateDataInVCProtocol {
    func updateUI() {
        DispatchQueue.main.async {
            if let testCase = self.vm.testCase {
                self.severityField.updateTextFieldValue(testCase.severity)
                self.statusField.updateTextFieldValue(testCase.status)
                self.priorityField.updateTextFieldValue(testCase.priority)
                self.behaviorField.updateTextFieldValue(testCase.behavior)
                self.typeField.updateTextFieldValue(testCase.type)
                self.layerField.updateTextFieldValue(testCase.layer)
                self.automationStatusField.updateTextFieldValue(testCase.automation)
            }
            LoadingIndicator.stopLoading()
        }
    }
    
    @objc func pull2Refresh() {
        DispatchQueue.main.async {
            self.updateUI()
        }
    }
}
