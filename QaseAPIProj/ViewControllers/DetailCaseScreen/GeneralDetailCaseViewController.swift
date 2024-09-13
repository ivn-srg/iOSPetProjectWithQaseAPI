//
//  GeneralDetailCaseViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit

enum CheckmarkButtonState {
    case active, inactive
}

class GeneralDetailCaseViewController: UIViewController {
    
    private let vm: DetailTabbarControllerViewModel
    weak var delegate: SwipeTabbarProtocol?
    private var isDataEditing = false
    
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
    
    private lazy var titleField = GeneralCaseTextField(
        textType: .name,
        textFieldValue: self.vm.testCase?.title ?? Constants.emptyText
    )
    
    private lazy var descriptionField = GeneralCaseTextField(
        textType: .description,
        textFieldValue: self.vm.testCase?.description ?? Constants.emptyText
    )
    
    private lazy var preconditionField = GeneralCaseTextField(
        textType: .precondition,
        textFieldValue: self.vm.testCase?.preconditions ?? Constants.emptyText
    )
    
    private lazy var postconditionField = GeneralCaseTextField(
        textType: .postcondition,
        textFieldValue: self.vm.testCase?.postconditions ?? Constants.emptyText
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
        view.backgroundColor = .white
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
        
        view.addGestureRecognizer(panRecognize)
    }
    
    private func setupCustomFields() {
        titleField.textFieldDelegate = self
        descriptionField.textFieldDelegate = self
        preconditionField.textFieldDelegate = self
        postconditionField.textFieldDelegate = self
        stackView.addArrangedSubview(titleField)
        stackView.addArrangedSubview(descriptionField)
        stackView.addArrangedSubview(preconditionField)
        stackView.addArrangedSubview(postconditionField)
    }
    
    @objc func swipeBetweenViewsDelegate() {
        self.delegate?.swipeBetweenViews(panRecognize)
    }
    
    /// method for saving changed main test case data
    @objc func saveMainTestCaseData() {
        if isDataEditing {
            isDataEditing = false
        }
    }
}

extension GeneralDetailCaseViewController: UpdateDataInVCProtocol {
    func updateUI() {
        DispatchQueue.main.async {
            if let testCase = self.vm.testCase {
                self.titleField.updateTextFieldValue(testCase.title)
                self.descriptionField.updateTextFieldValue(testCase.description ?? Constants.emptyText)
                self.preconditionField.updateTextFieldValue(testCase.preconditions ?? Constants.emptyText)
                self.postconditionField.updateTextFieldValue(testCase.postconditions ?? Constants.emptyText)
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

extension GeneralDetailCaseViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        isDataEditing = true
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct ViewControllerRepresentable: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> some UIViewController {
        return DetailTabBarController(caseId: 317)
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
