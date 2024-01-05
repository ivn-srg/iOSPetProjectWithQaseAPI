//
//  AuthViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import UIKit

class AuthViewController: UIViewController {
    
    let apiKey = ""
    var projects: Result = Result(
        total: 0,
        filtered: 0,
        count: 0,
        entities: Entity(
            title: "",
            code: "",
            counts: Counts(
                cases: 0,
                suites: 0,
                milestones: 0,
                runs: Runs(
                    total: 0,
                    active: 0),
                defects: Defects(
                    total: 0,
                    open: 0)
            )
        )
    )
    var urlString = "https://api.qase.io/v1/project?limit=10&offset=0"

    // MARK: - UI
    
    private lazy var viewCn: UIView = {
        let vc = UITableView()
        vc.translatesAutoresizingMaskIntoConstraints = false
        vc.backgroundColor = .clear
        return vc
    }()
    
    private var inputTokenField: UITextField = {
        let inf = UITextField()
        inf.translatesAutoresizingMaskIntoConstraints = false
        inf.backgroundColor = .clear
        return inf
    }()
    
    private var authButton: UIButton = {
        let ab = UIButton()
        ab.translatesAutoresizingMaskIntoConstraints = false
        return ab
    }()
    
    // MARK: - Lifecycle
    
    override func loadView() {
        super.loadView()
        setup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        authButton.addTarget(self, action: #selector(authorizate), for: .allEvents)
        
    }
    
    @objc private func authorizate() {
        
        func showError() {
            let ac = UIAlertController(title: "Неверный ввод", message: "Введите токен для авторизации на сервисе Qase", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
        
        if let inputTokenFieldText = inputTokenField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if !inputTokenFieldText.isEmpty {
                if let url = URL(string: urlString) {
                   if let data = try? Data(contentsOf: url) {
                       // we're OK to parse!
                       parse(json: data)
                       return
                   } else {  }
                } else {  }
            } else {
                showError()
            }
        } else {
            showError()
        }
    }
    
    func parse(json: Data) {
        let decoder = JSONDecoder()

        if let jsonProjects = try? decoder.decode(DataModel.self, from: json) {
            projects = jsonProjects.result
//            filteredProjects = petitions.filter({$0.title.lowercased().contains(searchText.lowercased())})
//            tableView.reloadData()
        }
    }
}

private extension AuthViewController {
    
    func setup() {
        
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
            
            authButton.topAnchor.constraint(equalTo: inputTokenField.bottomAnchor, constant: 5),
            authButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
        ])
    }
}
