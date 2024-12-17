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
        textType: .automationStatus,
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
            $0.edges.equalTo(view.safeAreaLayoutGuide.snp.edges)
        }
        
        stackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.centerX.equalToSuperview()
            $0.width.equalToSuperview().inset(30)
            $0.bottom.equalToSuperview().inset(40)
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
            self?.vm.changedTestCase?.isFlaky = isOn ? 1 : 0
            print("BooleanObject state: \(isOn)")
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
                self.severityField.updateValue()
                self.statusField.updateValue()
                self.priorityField.updateValue()
                self.behaviorField.updateValue()
                self.typeField.updateValue()
                self.layerField.updateValue()
                self.automationStatusField.updateValue()
                self.isFlakySwitch.configure(with: testCase.isFlaky == 1)
            }
        }
    }
    
    @objc func pull2Refresh() {
        Task { @MainActor in
            self.updateUI()
        }
    }
}
