//
//  CreatingProjectViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.09.2024.
//

import UIKit

final class CreatingProjectViewController: UIViewController {
    // MARK: - Fields
    private var viewModel: CreatingProjectViewModel

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
        uib.addTarget(self, action: #selector(createNewProject), for: .touchUpInside)
        return uib
    }()
    
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
    
    private lazy var titleTextView = GeneralCaseTextField(textType: .name, detailVM: viewModel)
    private lazy var codeTextView = GeneralCaseTextField(textType: .code, detailVM: viewModel)
    private lazy var descriptionTextView = GeneralCaseTextField(textType: .description, detailVM: viewModel)
    
    // MARK: - LifeCycle
    init(viewModel: CreatingProjectViewModel) {
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
                message: "Probably you didn't fill all fields, check it, please"
            )
        }
        viewModel.creatingFinishCallback = {
            showAlertController(on: self, title: "Success", message: "Your project was created successfully")
        }
        setupView()
    }
    
    // MARK: - other block
    private func setupView() {
        titleLabel.text = "Creating new project"
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
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.horizontalEdges.equalTo(view.safeAreaLayoutGuide.snp.horizontalEdges)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            $0.top.equalTo(customNavigationView.snp.bottom).offset(10)
        }
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.verticalEdges.equalToSuperview().inset(30)
            $0.centerX.equalToSuperview()
            $0.width.equalToSuperview().inset(30)
        }
        stackView.addArrangedSubview(titleTextView)
        stackView.addArrangedSubview(descriptionTextView)
        stackView.addArrangedSubview(codeTextView)
    }
    
    // MARK: - @objc func
    @objc func closeViewController() {
        dismiss(animated: true)
    }
}

extension CreatingProjectViewController: CheckEnablingRBBProtocol {
    func checkConditionAndToggleRightBarButton() {
        self.createButton.isEnabled = !viewModel.creatingProject.title.isEmpty
    }
    
    @objc func createNewProject() {
        viewModel.createNewProject()
    }
}
