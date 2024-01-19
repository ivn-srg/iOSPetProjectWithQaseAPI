//
//  ProjectsViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import UIKit

final class ProjectsViewController: UIViewController {
    
    var vm: ProjectsViewModel = ProjectsViewModel()
    
    var projectsDataSource: [ProjectTableCellViewModel] = []
    
    var suitesAndCasesCompletion: (() -> Void)?
    
//    var projects = [Project]()
    var suitesAndCaseData = [SuiteAndCaseData]()
    
//    init(viewModel: ProjectsViewModel) {
//        self.vm = viewModel
//        self.vm.updateDataSource()
//        super.init(nibName: nil, bundle: nil)
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    // MARK: - UI
    
    private lazy var tableVw: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .white
        tv.register(ProjectTableViewCell.self, forCellReuseIdentifier: ProjectTableViewCell.cellId)
        return tv
    }()
    

    
    // MARK: - Lifecycle
    
    override func loadView() {
        super.loadView()
        
        setupTableView()
        bindViewModel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        vm.updateDataSource()
    }
    
    func reloadTableView() {
            DispatchQueue.main.async {
                self.tableVw.reloadData()
            }
        }
    
    private func fetchSuitesJSON(_ token: String, projectCode: String) {
        let urlString = Constants.urlString(Constants.APIMethods.suite.rawValue, projectCode, 100, 0)
        
        APIManager.shared.fetchData(from: urlString, method: Constants.APIType.get.rawValue, token: token, modelType: SuitesDataModel.self) { [weak self] (result: Result<SuitesDataModel, Error>) in
            
            switch result {
            case .success(let jsonSuites):
                DispatchQueue.main.async {
                    self?.changeDataTypeToUniversalizeData(isSuite: true, targetUniversalList: &self!.suitesAndCaseData, suites: jsonSuites.result.entities, testCases: nil)
                    
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
    
    private func fetchCasesJSON(_ token: String, projectCode: String) {
        let urlString = Constants.urlString(Constants.APIMethods.cases.rawValue, projectCode, 100, 0)
        
        APIManager.shared.fetchData(from: urlString, method: Constants.APIType.get.rawValue, token: token, modelType: TestCasesModel.self) { [weak self] (result: Result<TestCasesModel, Error>) in
            
            switch result {
            case .success(let jsonCases):
                self?.changeDataTypeToUniversalizeData(isSuite: false, targetUniversalList: &self!.suitesAndCaseData, suites: nil, testCases: jsonCases.result.entities)
                
                DispatchQueue.main.async {
                    self?.suitesAndCasesCompletion!()
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
    
    private func changeDataTypeToUniversalizeData(
        isSuite: Bool,
        targetUniversalList: inout [SuiteAndCaseData],
        suites: [SuiteEntity]?,
        testCases: [TestEntity]?
    ) {
        if isSuite {
            guard let suites = suites else { return }
            
            for suite in suites {
                let universalItem = SuiteAndCaseData(
                    isSuite: true,
                    id: suite.id,
                    title: suite.title,
                    description: suite.description,
                    preconditions: suite.preconditions,
                    parent_id: suite.parent_id,
                    case_count: suite.cases_count
                )
                
                if suite.title == "Первый запуск мп" {
//                    print("\(suite.title) \(suite.parent_id)")
                }
                
                targetUniversalList.append(universalItem)
            }
        } else {
            guard let testCases = testCases else { return }
            
            for testCase in testCases {
                let universalItem = SuiteAndCaseData(
                    isSuite: false,
                    id: testCase.id,
                    title: testCase.title,
                    description: testCase.description,
                    preconditions: testCase.preconditions,
                    parent_id: nil,
                    case_count: nil,
                    priority: testCase.priority,
                    automation: testCase.automation,
                    suiteId: testCase.suiteId
                )
                
                targetUniversalList.append(universalItem)
            }
        }
        //        }
    }
    
    func bindViewModel() {
            vm.isLoadingData.bind { isLoading in
                guard let isLoading = isLoading else {
                    return
                }
                DispatchQueue.main.async {
                    if isLoading {
                        LoadingIndicator.startLoading()
                    } else {
                        LoadingIndicator.stopLoading()
                    }
                }
            }
            
        vm.projects.bind { [weak self] projects in
                guard let self = self,
                      let projects = projects else {
                    return
                }
                self.projectsDataSource = projects
                self.reloadTableView()
            }
        }
}

private extension ProjectsViewController {
    
    func setupTableView() {
        
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
        vm.numberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProjectTableViewCell.cellId, for: indexPath) as? ProjectTableViewCell else { return UITableViewCell()
        }
        cell.configureCell(with: projectsDataSource[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
//        LoadingIndicator.startLoading()
//        
//        suitesAndCasesCompletion = {
//            let vc = SuitesAndCasesTableViewController()
//            vc.suitesAndCaseData = self.suitesAndCaseData
//            vc.codeOfProject = self.projects[indexPath.row].code
//            self.navigationController?.pushViewController(vc, animated: true)
//            self.suitesAndCaseData.removeAll()
//        }
//        
//        self.fetchSuitesJSON(Constants.TOKEN, projectCode: self.projects[indexPath.row].code)
//        self.fetchCasesJSON(Constants.TOKEN, projectCode: self.projects[indexPath.row].code)
        vm.navigateTo(indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UITableViewDelegate

extension ProjectsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.separatorInset = UIEdgeInsets(top: 0, left: 1/*cell.bounds.size.width*/, bottom: 2, right: -5)
        
    }
}
