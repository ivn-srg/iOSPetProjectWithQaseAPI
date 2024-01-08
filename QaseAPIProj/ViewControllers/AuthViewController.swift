//
//  AuthViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import UIKit

class AuthViewController: UIViewController {
    
    let apiKey = ""
    var urlString = "https://api.qase.io/v1/project?limit=10&offset=0"
    
    // MARK: - UI
    
    private lazy var viewCn: UIView = {
        let vc = UITableView()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.backgroundColor = .white
        return vc
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
        setup()
        
        self.view.backgroundColor = .white
        
//        performSelector(inBackground: #selector(fetchJSON), with: nil)
    }
    
    @objc private func authorizate() {
        
        func showError() {
            let ac = UIAlertController(title: "Неверный ввод", message: "Введите токен для авторизации на сервисе Qase", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
        
        if let inputTokenFieldText = inputTokenField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if !inputTokenFieldText.isEmpty {
//                if let url = URL(string: urlString) {
//                    if let data = try? Data(contentsOf: url) {
//                        // we're OK to parse!
////                        parse(json: data)
//                        return
//                    } else {  }
//                } else {  }
                
                let vc = ProjectsViewController()
                vc.TOKEN = inputTokenFieldText
                navigationController?.pushViewController(vc, animated: true)
            } else {
                showError()
            }
        } else {
            showError()
        }
    }
}

private extension AuthViewController {
    
    func setup() {
        
        navigationController?.navigationBar.topItem?.title = "Authorization"
        
        inputTokenField.layer.borderWidth = 1
        inputTokenField.layer.cornerRadius = 10
        inputTokenField.layer.borderColor = UIColor.gray.cgColor
        
        authButton.setTitle("Next", for: .normal)
        authButton.addTarget(self, action: #selector(authorizate), for: .touchUpInside)
        
        view.addSubview(viewCn)
        view.addSubview(inputTokenField)
        view.addSubview(authButton)
        
        NSLayoutConstraint.activate([
            viewCn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            viewCn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            viewCn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            viewCn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            inputTokenField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            inputTokenField.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            inputTokenField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            inputTokenField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            authButton.topAnchor.constraint(equalTo: inputTokenField.bottomAnchor, constant: 10),
            authButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            authButton.widthAnchor.constraint(equalToConstant: 70)
        ])
    }
}
