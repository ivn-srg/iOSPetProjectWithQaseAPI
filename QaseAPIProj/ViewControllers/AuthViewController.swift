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
        logoImg.image = AppTheme.LogoApp

        inputTokenField.layer.borderWidth = 1
        inputTokenField.layer.cornerRadius = 8
        inputTokenField.layer.borderColor = UIColor.gray.cgColor
        inputTokenField.placeholder = "API Token"

        authButton.setTitle("Next", for: .normal)
        authButton.addTarget(self, action: #selector(authorizate), for: .touchUpInside)
        
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
            let vc = ProjectsViewController(totalCountOfProjects: self.viewModel.totalCountOfProject)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: - objc funcs
    @objc private func authorizate() {
        if let inputTokenFieldText = inputTokenField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if !inputTokenFieldText.isEmpty {
                TOKEN = inputTokenFieldText
                viewModel.fetchProjectsJSON()
            } else {
                showErrorAlert(titleAlert: "Incorrect input", messageAlert: "Input the API Token for authorization on Qase service")
            }
        } else {
            showErrorAlert(titleAlert: "Incorrect input", messageAlert: "Input the API Token for authorization on Qase service")
        }
    }
    
    @objc private func tapForFillingTextLb() {
        inputTokenField.text = KeychainLocal.QASE_API_KEY
        authorizate()
    }
}
