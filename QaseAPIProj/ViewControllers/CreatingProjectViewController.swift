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
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .close)
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
    
    private lazy var titleTextView = GeneralCaseTextField(textType: .name)
    private lazy var codeTextView = GeneralCaseTextField(textType: .code)
    private lazy var descriptionTextView = GeneralCaseTextField(textType: .description)
    
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
        
        setupView()
    }
    
    // MARK: - other block
    private func setupView() {
        titleLabel.text = "Creating new project"
        view.backgroundColor = .white
        
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.equalTo(view.safeAreaLayoutGuide.snp.leading).offset(10)
        }
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.horizontalEdges.equalTo(view.safeAreaLayoutGuide.snp.horizontalEdges)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            $0.top.equalTo(titleLabel.snp.bottom).offset(10)
        }
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.verticalEdges.equalTo(scrollView.snp.verticalEdges).inset(30)
            $0.centerX.equalTo(scrollView.snp.centerX)
            $0.width.equalTo(scrollView.snp.width).inset(30)
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
