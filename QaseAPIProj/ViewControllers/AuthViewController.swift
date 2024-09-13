//
//  AuthViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import UIKit

final class AuthViewController: UIViewController, NextViewControllerPusher {
    
    private var tapCount: Int = 0
    private var viewModel: AuthViewModel
    
    // MARK: - UI
    
    private lazy var viewCn: UIView = {
        let vc = UIView()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.backgroundColor = .white
        return vc
    }()
    
    private var logoImg: UIImageView = {
        let limg = UIImageView()
        limg.translatesAutoresizingMaskIntoConstraints = false
        limg.contentMode = .scaleAspectFit
        return limg
    }()
    
    private var inputTokenField: UITextField = {
        let inf = UITextField()
        inf.translatesAutoresizingMaskIntoConstraints = false
        inf.backgroundColor = .white
        inf.textColor = .systemGray
        inf.borderStyle = .roundedRect
        inf.layer.borderColor = AppTheme.fioletColor.cgColor
        return inf
    }()
    
    private var authButton: UIButton = {
        let ab = UIButton()
        ab.translatesAutoresizingMaskIntoConstraints = false
        ab.backgroundColor = AppTheme.fioletColor
        ab.layer.cornerRadius = 12
        ab.titleLabel?.textColor = .white
        return ab
    }()
    
    func showErrorAlert(titleAlert: String, messageAlert: String) {
        let ac = UIAlertController(title: titleAlert, message: messageAlert, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    // MARK: - Lifecycle
    
    init() {
        self.viewModel = AuthViewModel()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        self.view.backgroundColor = .white
        viewModel.delegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapForFillingTextLb))
        tapGestureRecognizer.numberOfTapsRequired = 3
        logoImg.addGestureRecognizer(tapGestureRecognizer)
        logoImg.isUserInteractionEnabled = true
    }
    
    // MARK: - UI
    
    func setup() {
        
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
    
    // MARK: - Router
    
    func pushToNextVC(to item: Int? = nil) {
        DispatchQueue.main.async {
            let vc = ProjectsViewController(totalCountOfProjects: self.viewModel.totalCountOfProject)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - objc funcs
    @objc private func authorizate() {
        if let inputTokenFieldText = inputTokenField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if !inputTokenFieldText.isEmpty {
                Constants.TOKEN = inputTokenFieldText
                viewModel.fetchProjectsJSON()
            } else {
                showErrorAlert(titleAlert: "Incorrect input", messageAlert: "Input the API Token for authorization on Qase service")
            }
        } else {
            showErrorAlert(titleAlert: "Incorrect input", messageAlert: "Input the API Token for authorization on Qase service")
        }
    }
    
    @objc private func tapForFillingTextLb() {
        inputTokenField.text = Keychain.QASE_API_KEY
        authorizate()
    }
}
