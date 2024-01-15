//
//  AuthViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import UIKit

class AuthViewController: UIViewController {
    
    private var tapCount: Int = 0
    
    var projects = [Project]()
    var statusOfResponse = false
    
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
        return inf
    }()
    
    private var authButton: UIButton = {
        let ab = UIButton()
        ab.translatesAutoresizingMaskIntoConstraints = false
        ab.backgroundColor = .systemBlue
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
    
    override func loadView() {
        super.loadView()
        setup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapForFillingTextLb))

        // Установите количество касаний, равное 3
        tapGestureRecognizer.numberOfTapsRequired = 3

        // Добавьте gesture recognizer к вашему изображению
        logoImg.addGestureRecognizer(tapGestureRecognizer)

        // Обязательно установите для изображения userInteractionEnabled в true, чтобы оно реагировало на жесты
        logoImg.isUserInteractionEnabled = true

    }
    
    @objc private func authorizate() {
        
        if let inputTokenFieldText = inputTokenField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if !inputTokenFieldText.isEmpty {
                
                Constants.TOKEN = inputTokenFieldText
                
                LoadingIndicator.startLoading()
                
                DispatchQueue.global().async {
                    self.fetchProjectsJSON(Constants.TOKEN)
                }
                
            } else {
                showErrorAlert(titleAlert: "Incorrect input", messageAlert: "Input the API Token for authorization on Qase service")
            }
        } else {
            showErrorAlert(titleAlert: "Incorrect input", messageAlert: "Input the API Token for authorization on Qase service")
        }
    }
    
    private func fetchProjectsJSON(_ token: String) {
        let urlString = Constants.urlString(Constants.APIMethods.project.rawValue, nil, 100, 0)
        
        APIManager.shared.fetchData(from: urlString, method: Constants.APIType.get.rawValue, token: token, modelType: ProjectDataModel.self) { [weak self] (result: Result<ProjectDataModel, Error>) in
            
            switch result {
            case .success(let jsonProjects):
                self?.projects = jsonProjects.result.entities
                self?.statusOfResponse = jsonProjects.status
                
                DispatchQueue.main.async {
                    LoadingIndicator.stopLoading()
                    
                    let vc = ProjectsViewController()
                    vc.projects = self!.projects
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            case .failure(let error):
                if let apiError = error as? APIError, apiError == .invalidURL {
                    DispatchQueue.main.async {
                        LoadingIndicator.stopLoading()
                        self?.showErrorAlert(titleAlert: "Error", messageAlert: "Invalid URL")
                    }
                } else {
                    DispatchQueue.main.async {
                        LoadingIndicator.stopLoading()
                        self?.showErrorAlert(titleAlert: "Something went wrong", messageAlert: "\(error)")
                    }
                }
            }
            
        }
    }
    
    @objc private func tapForFillingTextLb() {
//        tapCount += 1
//            
//        if tapCount == 3 {
//            // Здесь укажите ваш TextField и строку, которой хотите заполнить
            inputTokenField.text = "04e78090842e843ed490a3b129d5e46871b6399d0ca5fbfebaf12f547e0199d0"
            
//            // Сбросите счетчик
//            tapCount = 0
//        }
    }
}

private extension AuthViewController {
    
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
}
