//
//  ProfileViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 25.10.2024.
//

import UIKit

final class ProfileViewController: UIViewController {
    
    // MARK: - UI components
    private lazy var screenTitle: UILabel = {
        let title = UILabel()
        title.font = .systemFont(ofSize: 18, weight: .bold)
        title.text = "Profile".localized
        return title
    }()
    
    private lazy var exitButton: ButtonWithLeadingImage = {
        let exitBtn = ButtonWithLeadingImage(
            leadingImage: AppTheme.exitImage,
            title: "Exit".localized,
            actionWhileTouch: exitButtonTapped
        )
        exitBtn.translatesAutoresizingMaskIntoConstraints = false
        exitBtn.tintColor = .red
        exitBtn.backgroundColor = AppTheme.bgSecondaryColor
        exitBtn.layer.borderColor = AppTheme.fioletColor.cgColor
        exitBtn.layer.borderWidth = 1
        exitBtn.layer.cornerRadius = 12
        
        return exitBtn
    }()
    
    // MARK: - LifeCycle
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupConstraints()
    }
    // MARK: - other block
    private func setupConstraints() {
        view.addSubview(exitButton)
        view.addSubview(screenTitle)
        
        exitButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalToSuperview().inset(30)
        }
        
        screenTitle.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.centerX.equalToSuperview()
        }
    }
    
    @objc func exitButtonTapped() {
        executeWithErrorHandling {
            try await AuthManager.shared.logout()
            RealmManager.shared.dropDataBase()
        }
    }
}
