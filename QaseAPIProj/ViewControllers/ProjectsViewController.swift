//
//  ProjectsViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import UIKit

class ProjectsViewController: UIViewController {
    
    var suitesAndCasesCompletion: (() -> Void)?
    
    var projects = [Project]()
    var Token = ""
    var codeOfProject = ""
    var suitesOfProject = [Entity]()
    var casesOfProject = [TestEntity]()
    
    // MARK: - UI
    
    private lazy var tableVw: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .white
        tv.register(ProjectTableViewCell.self, forCellReuseIdentifier: ProjectTableViewCell.cellId)
        return tv
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
    }
    
    private func fetchSuitesJSON(_ token: String, projectCode: String) {
        let urlString = Constants.urlString(Constants.APIMethods.suite.rawValue, projectCode, 100, 0)
        
        APIManager.shared.fetchData(from: urlString, method: Constants.APIType.get.rawValue, token: token, modelType: SuitesDataModel.self) { [weak self] (result: Result<SuitesDataModel, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let jsonSuites):
                    self?.suitesOfProject = jsonSuites.result.entities
                    
                case .failure(let error):
                    if let apiError = error as? APIError, apiError == .invalidURL {
                        
                        LoadingIndicator.stopLoading()
                        self?.showErrorAlert(titleAlert: "Error", messageAlert: "Invalid URL")
                        
                    } else {
                        
                        LoadingIndicator.stopLoading()
                        self?.showErrorAlert(titleAlert: "Something went wrong", messageAlert: "\(error)")
                        
                    }
                }
            }
        }
    }
    
    private func fetchCasesJSON(_ token: String, projectCode: String) {
        let urlString = Constants.urlString(Constants.APIMethods.cases.rawValue, projectCode, 100, 0)
        
        APIManager.shared.fetchData(from: urlString, method: Constants.APIType.get.rawValue, token: token, modelType: TestCasesModel.self) { [weak self] (result: Result<TestCasesModel, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let jsonCases):
                    self?.casesOfProject = jsonCases.result.entities
                    self?.suitesAndCasesCompletion!()
                    
                case .failure(let error):
                    if let apiError = error as? APIError, apiError == .invalidURL {
                        
                        LoadingIndicator.stopLoading()
                        self?.showErrorAlert(titleAlert: "Error", messageAlert: "Invalid URL")
                        
                    } else {
                        
                        LoadingIndicator.stopLoading()
                        self?.showErrorAlert(titleAlert: "Something went wrong", messageAlert: "\(error)")
                        
                    }
                }
            }
            
        }
    }
}

private extension ProjectsViewController {
    
    func setup() {
        
        title = "Projects"
        navigationItem.largeTitleDisplayMode = .never
        
        view.backgroundColor = .white
        
        tableVw.delegate = self
        tableVw.dataSource = self
        
        view.addSubview(tableVw)
        
        NSLayoutConstraint.activate([
            tableVw.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableVw.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableVw.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableVw.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
    }
}

// MARK: - UITableViewDataSource

extension ProjectsViewController: UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return projects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProjectTableViewCell.cellId, for: indexPath) as! ProjectTableViewCell
        let project = projects[indexPath.row]
        
        cell.configure(with: project)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        LoadingIndicator.startLoading()
        
        suitesAndCasesCompletion = {
            let vc = SuitesAndCasesTableViewController()
            vc.codeOfProject = self.projects[indexPath.row].code
            vc.suitesOfProject = self.suitesOfProject
            vc.casesOfProject = self.casesOfProject
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        self.fetchSuitesJSON(Constants.TOKEN, projectCode: self.projects[indexPath.row].code)
        self.fetchCasesJSON(Constants.TOKEN, projectCode: self.projects[indexPath.row].code)
    }
}

// MARK: - UITableViewDelegate

extension ProjectsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.separatorInset = UIEdgeInsets(top: 0, left: 1/*cell.bounds.size.width*/, bottom: 2, right: -5)
        
    }
}
