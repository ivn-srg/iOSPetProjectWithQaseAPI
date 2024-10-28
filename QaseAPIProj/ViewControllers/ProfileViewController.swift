//
//  ProfileViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 25.10.2024.
//

import UIKit

final class ProfileViewController: UIViewController {
    // MARK: - Fields
    
    // MARK: - UI components
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
        
        exitButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.equalToSuperview().inset(30)
        }
    }
    
    @objc func exitButtonTapped() {
        executeWithErrorHandling {
            try AuthManager.shared.logout()
        }
    }
}
