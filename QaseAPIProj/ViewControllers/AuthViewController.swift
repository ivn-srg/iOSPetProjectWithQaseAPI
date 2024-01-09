//
//  AuthViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import UIKit

class AuthViewController: UIViewController {
    
    
    var projects = [Entity]()
    var TOKEN = ""
    
    // MARK: - UI
    
    private lazy var viewCn: UIView = {
        let vc = UITableView()
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
    
    // MARK: - Lifecycle
    
    override func loadView() {
        super.loadView()
        setup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
    }
    
    @objc private func authorizate() {
        
        func showError() {
            let ac = UIAlertController(title: "Incorrect input", message: "Input the API Token for authorization on Qase service", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
        
        if let inputTokenFieldText = inputTokenField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if !inputTokenFieldText.isEmpty {
                
                DispatchQueue.global().async {
                    self.fetchJSON(inputTokenFieldText)
                    
                }
                
                let vc = ProjectsViewController()
                vc.projects = self.projects
                self.navigationController?.pushViewController(vc, animated: true)
                
            } else {
                showError()
            }
        } else {
            showError()
        }
    }
    
    private func fetchJSON(_ token: String) {
        let urlString: String = "https://api.qase.io/v1/project?limit=10&offset=0"
        
        // Создаем URL и URLRequest
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        
        // Устанавливаем HTTP метод
        request.httpMethod = "GET"
        
        // Устанавливаем свой заголовок
        request.addValue(token, forHTTPHeaderField: "Token")
        
        // Отправляем запрос
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Проверяем наличие ошибок
            if let error = error {
                DispatchQueue.main.async {
                    let ac = UIAlertController(title: "Something went wrong", message: "\(error)", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
            } else if let data = data {
                // Парсим ответ
                let decoder = JSONDecoder()
                do {
                    // Пробуем декодировать полученные данные
                    let jsonProjects = try decoder.decode(ProjectDataModel.self, from: data)
                    // Операции с результатами парсинга
                    self.projects = jsonProjects.result.entities
                    
                } catch {
                    DispatchQueue.main.async {
                        let ac = UIAlertController(title: "Server Error", message: "Invalid network response", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
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
        
        view.addSubview(viewCn)
        view.addSubview(logoImg)
        view.addSubview(inputTokenField)
        view.addSubview(authButton)
        
        NSLayoutConstraint.activate([
            viewCn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            viewCn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            viewCn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            viewCn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            logoImg.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            logoImg.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            logoImg.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 30),
            logoImg.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -30),
            
            inputTokenField.topAnchor.constraint(equalTo: logoImg.bottomAnchor, constant: 20),
            inputTokenField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            inputTokenField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 30),
            inputTokenField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -30),
            
            authButton.topAnchor.constraint(equalTo: inputTokenField.bottomAnchor, constant: 30),
            authButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            authButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 30),
            authButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -30),
        ])
    }
}
