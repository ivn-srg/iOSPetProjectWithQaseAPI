//
//  GeneralDetailCaseViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit

final class GeneralDetailCaseViewController: UIViewController {
    
    private let vm: DetailTabbarControllerViewModel
    weak var delegate: DetailTestCaseProtocol?
    private var isDataEditing = false
    
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
    
    private lazy var titleField = GeneralCaseTextField(
        textType: .title,
        textViewValue: vm.testCase?.title,
        detailVM: vm
    )
    
    private lazy var descriptionField = GeneralCaseTextField(
        textType: .description,
        textViewValue: vm.testCase?.description,
        detailVM: vm
    )
    
    private lazy var preconditionField = GeneralCaseTextField(
        textType: .precondition,
        textViewValue: vm.testCase?.preconditions,
        detailVM: vm
    )
    
    private lazy var postconditionField = GeneralCaseTextField(
        textType: .postcondition,
        textViewValue: vm.testCase?.postconditions,
        detailVM: vm
    )
    
    private lazy var panRecognize: UISwipeGestureRecognizer = {
        let gestureRecognizer = UISwipeGestureRecognizer()
        gestureRecognizer.addTarget(self, action: #selector(swipeBetweenViewsDelegate))
        return gestureRecognizer
    }()
    
    // MARK: - Lifecycle

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
        setupCustomFields()
        updateUI()
    }
    
    // MARK: - Setup Methods for UI
    private func setupView() {
        view.addSubview(scrollView)
        
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide.snp.edges)
        }
        
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.verticalEdges.equalTo(scrollView.contentLayoutGuide.snp.verticalEdges).inset(20)
            $0.horizontalEdges.equalTo(scrollView.frameLayoutGuide.snp.horizontalEdges).inset(20)
        }
        
        view.addGestureRecognizer(panRecognize)
    }
    
    private func setupCustomFields() {
        stackView.addArrangedSubview(titleField)
        stackView.addArrangedSubview(descriptionField)
        stackView.addArrangedSubview(preconditionField)
        stackView.addArrangedSubview(postconditionField)
    }
    
    @objc func swipeBetweenViewsDelegate() {
        guard let delegate = delegate else { return }
        delegate.swipeBetweenViews(panRecognize)
    }
}

extension GeneralDetailCaseViewController: DetailTestCaseProtocol {
    func swipeBetweenViews(_ gesture: UISwipeGestureRecognizer) {
        print("swipeBetweenViews called")
    }
    
    func checkConditionAndToggleRightBarButton() {
        print("checkConditionAndToggleRightBarButton called")
    }
    
    func updateUI() {
        Task { @MainActor in
            if let testCase = vm.testCase {
                titleField.updateTextViewValue(testCase.title)
                descriptionField.updateTextViewValue(testCase.description)
                preconditionField.updateTextViewValue(testCase.preconditions)
                postconditionField.updateTextViewValue(testCase.postconditions)
            }
        }
    }
    
    @objc func pull2Refresh() {
        Task { @MainActor in
            updateUI()
        }
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ViewControllerRepresentable: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> some UIViewController {
        return TestCaseViewController(caseId: 317)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
}

struct ViewController_Preview: PreviewProvider {
    static var previews: some View {
        ViewControllerRepresentable()
    }
}
#endif
