//
//  CreateSuiteOrCaseViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 21.09.2024.
//

import UIKit

enum CreatingEntitySelect: String {
    case suite = "Suite"
    case testCase = "Test case"
}

final class CreateSuiteOrCaseViewController: UIViewController {
    // MARK: - Fields
    private var viewModel: CreateSuiteOrCaseViewModel

    // MARK: - UI components
    private lazy var customNavigationView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .close)
        var config = button.configuration
        config?.buttonSize = .medium
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = .lightGray
        button.addTarget(self, action: #selector(closeViewController), for: .touchUpInside)
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = .systemFont(ofSize: 20, weight: .bold)
        title.numberOfLines = 1
        return title
    }()
    
    private lazy var createButton: UIButton = {
        let uib = UIButton(type: .system)
        uib.translatesAutoresizingMaskIntoConstraints = false
        uib.setTitle("Create", for: .normal)
        uib.isEnabled = false
        uib.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        uib.addTarget(self, action: #selector(createNewEntity), for: .touchUpInside)
        return uib
    }()
    
    private lazy var segmentControll: UISegmentedControl = {
        let segmentItems = [CreatingEntitySelect.suite.rawValue, CreatingEntitySelect.testCase.rawValue]
        let segment = UISegmentedControl(items: segmentItems)
        segment.isUserInteractionEnabled = true
        segment.translatesAutoresizingMaskIntoConstraints = false
        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: #selector(changeAppearingView), for: .valueChanged)
        return segment
    }()
    
    private lazy var suiteView: UIView = {
        let av = CreateSuiteView(linkedViewModel: viewModel)
        av.translatesAutoresizingMaskIntoConstraints = false
        av.isUserInteractionEnabled = true
        return av
    }()
    
    private lazy var testCaseView: UIView = {
        let av = CreateTestCaseView(linkedViewModel: viewModel)
        av.translatesAutoresizingMaskIntoConstraints = false
        av.isUserInteractionEnabled = true
        return av
    }()
    
    // MARK: - LifeCycle
    init(viewModel: CreateSuiteOrCaseViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.delegate = self
        viewModel.emptyFieldsClosure = {
            showAlertController(
                on: self,
                title: "Not enough",
                message: "Probably you didn't fill all fields, check it, please")
        }
        viewModel.creatingFinishCallback = {
            showAlertController(
                on: self,
                title: "Success",
                message: "Your entity was created successfully") { _ in
                    self.dismiss(animated: true)
                }
        }
        setupView()
    }
    
    // MARK: - other block
    private func setupView() {
        titleLabel.text = "Creating new entity"
        view.backgroundColor = .white
        
        view.addSubview(customNavigationView)
        customNavigationView.addSubview(closeButton)
        closeButton.snp.makeConstraints {
            $0.centerY.leading.equalToSuperview()
        }
        customNavigationView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.horizontalEdges.equalTo(view.safeAreaLayoutGuide.snp.horizontalEdges).inset(16)
            $0.height.equalTo(closeButton.snp.height)
        }
        customNavigationView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        customNavigationView.addSubview(createButton)
        createButton.snp.makeConstraints {
            $0.centerY.trailing.equalToSuperview()
        }
        view.addSubview(segmentControll)
        segmentControll.snp.makeConstraints {
            $0.top.equalTo(customNavigationView.snp.bottom).offset(30)
            $0.horizontalEdges.equalToSuperview().inset(16)
        }
        view.addSubview(testCaseView)
        testCaseView.snp.makeConstraints {
            $0.top.equalTo(segmentControll.snp.bottom).offset(10)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }
        view.addSubview(suiteView)
        suiteView.snp.makeConstraints {
            $0.top.equalTo(segmentControll.snp.bottom).offset(10)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview()
        }
    }
    
    // MARK: - @objc func
    @objc func closeViewController() {
        dismiss(animated: true)
    }
    
    @objc func changeAppearingView(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            suiteView.isHidden = false
            testCaseView.isHidden = true
            viewModel.creatingEntityIsSuite = true
        } else {
            suiteView.isHidden = true
            testCaseView.isHidden = false
            viewModel.creatingEntityIsSuite = false
        }
    }
}

extension CreateSuiteOrCaseViewController: CheckEnablingRBBProtocol {
    func checkConditionAndToggleRightBarButton() {
        self.createButton.isEnabled = viewModel.creatingEntityIsSuite ? !viewModel.creatingSuite.title.isEmpty
        : !viewModel.creatingTestCase.title.isEmpty
    }
    
    @objc func createNewEntity() {
        viewModel.createNewEntity()
    }
}
