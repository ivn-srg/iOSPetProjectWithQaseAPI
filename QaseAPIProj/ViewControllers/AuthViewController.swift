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
        return limg
    }()
    
    private var inputTokenField: UITextField = {
        let inf = TextFieldWithPadding()
        inf.translatesAutoresizingMaskIntoConstraints = false
        inf.backgroundColor = AppTheme.bgSecondaryColor
        inf.textColor = AppTheme.fioletColor
        inf.layer.borderWidth = 1
        inf.layer.cornerRadius = 12
        inf.layer.borderColor = UIColor.gray.cgColor
        inf.placeholder = "Input your API Token"
        inf.delegate = inf
        return inf
    }()
    
    private var authButton: UIButton = {
        let ab = UIButton()
        ab.translatesAutoresizingMaskIntoConstraints = false
        ab.backgroundColor = AppTheme.fioletColor
        ab.layer.cornerRadius = 12
        ab.titleLabel?.textColor = .white
        ab.setTitle("Next", for: .normal)
        return ab
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapForFillingTextLb))
        tapGestureRecognizer.numberOfTapsRequired = 3
        logoImg.addGestureRecognizer(tapGestureRecognizer)
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
        DispatchQueue.main.async {
            let vc = MainTabbarViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - objc funcs
    @objc private func authorizate() {
        if let inputToken = inputTokenField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !inputToken.isEmpty {
            do {
                try AuthManager.shared.loggedIn(token: inputToken)
//                pushToNextVC()
            } catch {
                UIAlertController.showSimpleAlert(
                    on: self,
                    title: "errorTitle".localized,
                    message: error.localizedDescription
                )
            }
        } else {
            UIAlertController.showSimpleAlert(
                on: self,
                title: "Incorrect input",
                message: "Input the API Token for authorization on Qase service"
            )
        }
    }
    
    @objc private func tapForFillingTextLb() {
        inputTokenField.text = KeychainLocal.QASE_API_KEY
        authorizate()
    }
}
