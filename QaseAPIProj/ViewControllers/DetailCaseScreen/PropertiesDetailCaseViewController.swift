//
//  PropertiesDetailCaseViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit

class PropertiesDetailCaseViewController: UIViewController {
    
    let vm: DetailTabbarControllerViewModel
    
    // MARK: - UI
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
    
    private lazy var severityField = PropertiesPickerTextField(
        textType: .severity,
        detailCaseVM: vm
    )
    
    private lazy var statusField = PropertiesPickerTextField(
        textType: .status,
        detailCaseVM: vm
    )
    
    private lazy var priorityField = PropertiesPickerTextField(
        textType: .priority,
        detailCaseVM: vm
    )
    
    private lazy var behaviorField = PropertiesPickerTextField(
        textType: .behavior,
        detailCaseVM: vm
    )
    
    private lazy var typeField = PropertiesPickerTextField(
        textType: .type,
        detailCaseVM: vm
    )
    
    private lazy var layerField = PropertiesPickerTextField(
        textType: .layer,
        detailCaseVM: vm
    )
    
    private lazy var automationStatusField = PropertiesPickerTextField(
        textType: .automation,
        detailCaseVM: vm
    )
    
    private lazy var isFlakySwitch: SwitcherWithTitle = {
        let sw = SwitcherWithTitle(title: "Is Flaky".localized, testCaseVM: vm)
        sw.translatesAutoresizingMaskIntoConstraints = false
        return sw
    }()
    
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
            $0.edges.equalToSuperview()
        }
        
        stackView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide.snp.edges).inset(20)
            $0.width.equalToSuperview().inset(20)
        }
        stackView.addArrangedSubview(severityField)
        stackView.addArrangedSubview(statusField)
        stackView.addArrangedSubview(priorityField)
        stackView.addArrangedSubview(behaviorField)
        stackView.addArrangedSubview(typeField)
        stackView.addArrangedSubview(layerField)
        stackView.addArrangedSubview(automationStatusField)
        stackView.addArrangedSubview(isFlakySwitch)
        isFlakySwitch.snp.makeConstraints {
            $0.height.equalTo(40)
        }
        
        isFlakySwitch.switchValueChanged = { [weak self] isOn in
            guard let self else { return }
            
            self.vm.changedTestCase?.isFlaky = isOn
        }
    }
}

extension PropertiesDetailCaseViewController: DetailTestCaseProtocol {
    func swipeBetweenViews(_ gesture: UISwipeGestureRecognizer) {
        print("swipeBetweenViews called")
    }
    
    func checkConditionAndToggleRightBarButton() {
        print("checkConditionAndToggleRightBarButton called")
    }
    
    func updateUI() {
        Task { @MainActor in
            if let testCase = self.vm.changedTestCase {
                severityField.updateValue()
                statusField.updateValue()
                priorityField.updateValue()
                behaviorField.updateValue()
                typeField.updateValue()
                layerField.updateValue()
                automationStatusField.updateValue()
                isFlakySwitch.configure(with: testCase.isFlaky)
            }
        }
    }
    
    @objc func pull2Refresh() {
        Task { @MainActor in
            self.updateUI()
        }
    }
}
