//
//  SuitesAndCasesTableViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 09.01.2024.
//

import UIKit


class SuitesAndCasesTableViewController: UITableViewController {
    
    var codeOfProject = ""
    var Token = ""
    var suitesOfProject = [Entity]()
    var casesOfProject = [TestEntity]()
    
    // MARK: - UI
    
    private lazy var tableVw: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .white
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return tv
    }()
    
    func showErrorAlert(titleAlert: String, messageAlert: String) {
        let ac = UIAlertController(title: titleAlert, message: messageAlert, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    // MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        
        view.backgroundColor = .white
        
        tableVw.delegate = self
        tableVw.dataSource = self
        
        LoadingIndicator.stopLoading()
    }
    
    private func fetchSuitesJSON(_ token: String) {
        let urlString = "https://api.qase.io/v1/suite/\(codeOfProject)?limit=100&offset=0"

        APIManager.shared.fetchData(from: urlString, method: "GET", token: token, modelType: SuitesDataModel.self) { [weak self] (result: Result<SuitesDataModel, Error>) in
            DispatchQueue.global().async {

                switch result {
                case .success(let jsonSuites):
                    self?.suitesOfProject = jsonSuites.result.entities

                case .failure(let error):
                    if let apiError = error as? APIError, apiError == .invalidURL {
                        DispatchQueue.main.async {
                            self?.showErrorAlert(titleAlert: "Error", messageAlert: "Invalid URL")
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.showErrorAlert(titleAlert: "Something went wrong", messageAlert: "\(error)")
                        }
                    }
                }
            }
        }
    }
    
    private func fetchCasesJSON(_ token: String) {
        let urlString = "https://api.qase.io/v1/case/\(codeOfProject)?limit=100&offset=0"

        APIManager.shared.fetchData(from: urlString, method: "GET", token: token, modelType: TestCasesModel.self) { [weak self] (result: Result<TestCasesModel, Error>) in
            DispatchQueue.global().async {

                switch result {
                case .success(let jsonCases):
                    self?.casesOfProject = jsonCases.result.entities

                case .failure(let error):
                    if let apiError = error as? APIError, apiError == .invalidURL {
                        DispatchQueue.main.async {
                            self?.showErrorAlert(titleAlert: "Error", messageAlert: "Invalid URL")
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.showErrorAlert(titleAlert: "Something went wrong", messageAlert: "\(error)")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        //        print("count of suites: \(suitesOfProject.filter( {$0.parentId == nil}).count)")
        return suitesOfProject.filter( {$0.parent_id == nil} ).count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = self.suitesOfProject.filter( {$0.parent_id == nil} )[section].title
        return section
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        let suite = suitesOfProject[section]
        let testCasesInSuite = casesOfProject.filter( {$0.suiteId == suite.id} )
        return testCasesInSuite.count
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableVw.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        
        let suite = suitesOfProject[indexPath.section]
        let testCasesInSuite = casesOfProject.filter( {$0.suiteId == suite.id} )
        let testCase = testCasesInSuite[indexPath.row]
        
        switch testCase.automation {
        case 0:
            content.image = Constants.notAutomationImage
        case 1:
            content.image = Constants.toBeAutomationImage
        case 2:
            content.image = Constants.automationImage
        default:
            content.image = nil
        }
        
//        switch testCase.priority {
//        case 1:
//            content.image = Constants.highPriorityImage
//        case 2:
//            content.image = Constants.mediumPriorityImage
//        case 3:
//            content.image = Constants.lowPriorityImage
//        default:
//            content.image = nil
//        }
        content.text = testCase.title
        
        content.secondaryTextProperties.color = .gray
        content.secondaryText = testCase.description
        
        cell.contentConfiguration = content
    
        return cell
        
    }
    
}


extension SuitesAndCasesTableViewController {
    
    func setup() {
        
        title = "Test suites"
        navigationItem.largeTitleDisplayMode = .never
        
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

