//
//  AuthViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import UIKit

class AuthViewController: UIViewController {
    
    
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
    
    private var progView: UIActivityIndicatorView = {
        let pv = UIActivityIndicatorView(style: .large)
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()
    
    private var textLoader: UILabel = {
        let tl = UILabel()
        tl.translatesAutoresizingMaskIntoConstraints = false
        tl.text = "Loading..."
        return tl
    }()
    
    private var darkView: UIView = {
        let dw = UIView()
        dw.translatesAutoresizingMaskIntoConstraints = false
        dw.backgroundColor = UIColor(white: 0, alpha: 0.5)
        return dw
    }()
    
    // MARK: - Lifecycle
    
    override func loadView() {
        super.loadView()
        setup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
    }
    
    func showErrorAlert(titleAlert: String, messageAlert: String) {
        let ac = UIAlertController(title: titleAlert, message: messageAlert, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    @objc private func authorizate() {
        
        if let inputTokenFieldText = inputTokenField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if !inputTokenFieldText.isEmpty {
                
                Constants.TOKEN = inputTokenFieldText
                
                self.darkView.isHidden = false
                progView.startAnimating()
                
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
    
    private func ValidationToken(token: String) -> Bool {
        
        
        return false
    }
    
    private func fetchProjectsJSON(_ token: String) {
        let urlString: String = "https://api.qase.io/v1/project?limit=100&offset=0"
        
        // Создаем URL и URLRequest
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        
        // Устанавливаем HTTP метод
        request.httpMethod = "GET"
        
        // Устанавливаем свой заголовок
        request.addValue(token, forHTTPHeaderField: "Token")
        
        // Отправляем запрос
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                DispatchQueue.main.async {
                    self.darkView.isHidden = true
                    self.progView.stopAnimating()
                    self.showErrorAlert(titleAlert: "Something went wrong", messageAlert: "\(error)")
                }
            } else if let data = data {
                // Парсим ответ
                let decoder = JSONDecoder()
                do {
                    // Пробуем декодировать полученные данные
                    let jsonProjects = try decoder.decode(ProjectDataModel.self, from: data)
                    // Операции с результатами парсинга
                    self.projects = jsonProjects.result.entities
                    self.statusOfResponse = jsonProjects.status
                    
                    DispatchQueue.main.async {
                        self.darkView.isHidden = true
                        self.progView.stopAnimating()
                        let vc = ProjectsViewController()
                        vc.Token = Constants.TOKEN
                        vc.projects = self.projects
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                } catch {
                    do {
                        let jsonProjects = try decoder.decode(ProjectErrorDataModel.self, from: data)
                        DispatchQueue.main.async {
                            self.darkView.isHidden = true
                            self.progView.stopAnimating()
                            self.showErrorAlert(titleAlert: "Error", messageAlert: jsonProjects.error)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.darkView.isHidden = true
                            self.progView.stopAnimating()
                            self.showErrorAlert(titleAlert: "Error", messageAlert: "Invalid network response")
                        }
                    }
                }
            }
        }
        task.resume()
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
        
        progView.layer.borderColor = UIColor(.gray).cgColor
        progView.layer.borderWidth = 1
        progView.layer.cornerRadius = 12
        progView.backgroundColor = .white
        progView.color = .systemBlue
        
        darkView.isHidden = true
        
        view.addSubview(viewCn)
        view.addSubview(logoImg)
        view.addSubview(inputTokenField)
        view.addSubview(authButton)
        view.addSubview(darkView)
        
        darkView.addSubview(progView)
        
        NSLayoutConstraint.activate([
            viewCn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            viewCn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            viewCn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            viewCn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            darkView.topAnchor.constraint(equalTo: view.topAnchor),
            darkView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            darkView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            darkView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
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
            
            progView.centerYAnchor.constraint(equalTo: darkView.centerYAnchor),
            progView.centerXAnchor.constraint(equalTo: darkView.centerXAnchor),
            progView.widthAnchor.constraint(equalToConstant: 100),
            progView.heightAnchor.constraint(equalToConstant: 100),
        ])
    }
}
