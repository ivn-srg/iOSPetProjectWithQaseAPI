//
//  AuthViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import UIKit

final class AuthViewController: UIViewController {
    
    // MARK: - UI
    
    private lazy var viewCn: UIView = {
        let vc = UIView()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.backgroundColor = .white
        return vc
    }()
    
    private lazy var logoImg: UIImageView = {
        let limg = UIImageView()
        limg.translatesAutoresizingMaskIntoConstraints = false
        limg.contentMode = .scaleAspectFit
        return limg
    }()
    
    private lazy var inputTokenField: UITextField = {
        let inf = UITextField()
        inf.translatesAutoresizingMaskIntoConstraints = false
        inf.backgroundColor = .white
        inf.textColor = .systemGray
        inf.borderStyle = .roundedRect
        return inf
    }()
    
    private lazy var authButton: UIButton = {
        let ab = UIButton()
        ab.translatesAutoresizingMaskIntoConstraints = false
        ab.backgroundColor = .systemBlue
        ab.layer.cornerRadius = 12
        ab.titleLabel?.textColor = .white
        return ab
    }()
    
    // MARK: - Lifecycle
    
    override func loadView() {
        super.loadView()
        setup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addDebugOptions()
    }
    
    @objc private func authorizate() {
        
        if let inputTokenFieldText = inputTokenField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if !inputTokenFieldText.isEmpty {
                
                Constants.TOKEN = inputTokenFieldText
                
                let vc = ProjectsViewController()
                self.navigationController?.pushViewController(vc, animated: true)
                
            } else {
                showErrorAlert(titleAlert: "Incorrect input", messageAlert: "Input the API Token for authorization on Qase service")
            }
        } else {
            showErrorAlert(titleAlert: "Incorrect input", messageAlert: "Input the API Token for authorization on Qase service")
        }
    }
    
    @objc func tapForFillingTextLb() {
        inputTokenField.text = ""
        authorizate()
    }
    
    func addDebugOptions() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapForFillingTextLb))
        tapGestureRecognizer.numberOfTapsRequired = 3
        logoImg.addGestureRecognizer(tapGestureRecognizer)
        logoImg.isUserInteractionEnabled = true
    }
}

private extension AuthViewController {
    
    func setup() {
        
        view.backgroundColor = .white
        
        logoImg.image = Assets.LogoApp
        
        inputTokenField.layer.borderWidth = 1
        inputTokenField.layer.cornerRadius = 8
        inputTokenField.layer.borderColor = UIColor.gray.cgColor
        inputTokenField.placeholder = "API Token"
        
        authButton.setTitle("Next", for: .normal)
        authButton.addTarget(self, action: #selector(authorizate), for: .touchUpInside)
        
        view.addSubview(viewCn)
        view.addSubview(logoImg)
        view.addSubview(inputTokenField)
        view.addSubview(authButton)
        
        NSLayoutConstraint.activate([
            viewCn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            viewCn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            viewCn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            viewCn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            logoImg.topAnchor.constraint(equalTo: viewCn.topAnchor, constant: 30),
            logoImg.centerXAnchor.constraint(equalTo: viewCn.centerXAnchor),
            logoImg.leadingAnchor.constraint(equalTo: viewCn.leadingAnchor, constant: 30),
            logoImg.trailingAnchor.constraint(equalTo: viewCn.trailingAnchor, constant: -30),
            
            inputTokenField.topAnchor.constraint(equalTo: logoImg.bottomAnchor, constant: 20),
            inputTokenField.centerXAnchor.constraint(equalTo: viewCn.centerXAnchor),
            inputTokenField.leadingAnchor.constraint(equalTo: viewCn.leadingAnchor, constant: 30),
            inputTokenField.trailingAnchor.constraint(equalTo: viewCn.trailingAnchor, constant: -30),
            
            authButton.topAnchor.constraint(equalTo: inputTokenField.bottomAnchor, constant: 30),
            authButton.centerXAnchor.constraint(equalTo: viewCn.centerXAnchor),
            authButton.leadingAnchor.constraint(equalTo: viewCn.leadingAnchor, constant: 30),
            authButton.trailingAnchor.constraint(equalTo: viewCn.trailingAnchor, constant: -30),
        ])
    }
}
