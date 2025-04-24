//
//  AuthViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import UIKit

final class AuthViewController: UIViewController, NextViewControllerPusher {
    private var tapCount: Int = 0
    
    // MARK: - UI
    private var logoImg: UIImageView = {
        let limg = UIImageView()
        limg.translatesAutoresizingMaskIntoConstraints = false
        limg.contentMode = .scaleAspectFit
        limg.image = AppTheme.LogoApp
        limg.isUserInteractionEnabled = true
        limg.accessibilityIdentifier = "logoImg"
        return limg
    }()
    
    private var inputTokenField: UITextField = {
        let inf = TextFieldWithPadding()
        inf.translatesAutoresizingMaskIntoConstraints = false
        inf.backgroundColor = AppTheme.bgSecondaryColor
        inf.textColor = .label
        inf.layer.borderWidth = 1
        inf.layer.cornerRadius = 12
        inf.layer.borderColor = UIColor.gray.cgColor
        inf.placeholder = "Input your API Token".localized
        inf.delegate = inf
        inf.accessibilityIdentifier = "inputTextField"
        return inf
    }()
    
    private var authButton: UIButton = {
        let ab = UIButton()
        ab.translatesAutoresizingMaskIntoConstraints = false
        ab.backgroundColor = AppTheme.fioletColor
        ab.layer.cornerRadius = 12
        ab.titleLabel?.textColor = .white
        ab.setTitle("Next".localized, for: .normal)
        ab.accessibilityIdentifier = "authButton"
        return ab
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        
        let longTapGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longTapForFillingTextLb))
        logoImg.addGestureRecognizer(longTapGestureRecognizer)
        
        authButton.addTarget(self, action: #selector(authorizate), for: .touchUpInside)
    }
    
    // MARK: - UI
    func setup() {
        view.backgroundColor = AppTheme.bgPrimaryColor
        view.addSubview(logoImg)
        view.addSubview(inputTokenField)
        view.addSubview(authButton)
        
        logoImg.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(30)
            $0.top.equalToSuperview().offset(130)
            $0.centerX.equalToSuperview()
        }
        
        inputTokenField.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(30)
            $0.top.equalTo(logoImg.snp.bottom).offset(20)
            $0.centerX.equalToSuperview()
        }
        
        authButton.snp.makeConstraints {
            $0.horizontalEdges.equalToSuperview().inset(30)
            $0.top.equalTo(inputTokenField.snp.bottom).offset(30)
            $0.centerX.equalToSuperview()
        }
    }
    
    // MARK: - Router
    
    func pushToNextVC(to item: Int? = nil) {
        Task { @MainActor in
            let vc = MainTabbarViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - objc funcs
    @objc private func authorizate() {
        Task { @MainActor in
            if let inputToken = inputTokenField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !inputToken.isEmpty {
                do {
                    try await AuthManager.shared.loggedIn(token: inputToken)
                } catch API.NetError.invalidCredantials {
                    UIAlertController.showSimpleAlert(
                        on: self,
                        title: "Invalid Credantials".localized,
                        message: "You inputed wrong API Token. Try again"
                    )
                } catch {
                    UIAlertController.showSimpleAlert(
                        on: self,
                        title: "Something went wrong".localized,
                        message: error.localizedDescription
                    )
                }
            } else {
                UIAlertController.showSimpleAlert(
                    on: self,
                    title: "Incorrect input".localized,
                    message: "Input the API Token for authorization on Qase service".localized
                )
            }
        }
    }
    
    @objc private func longTapForFillingTextLb() {
        // Token for demo purposes
        inputTokenField.text = "df3498cf743579b78d3c34d6640e1e2e39edf9ea2530cdf43eb848156126519e"
        authorizate()
    }
}
