//
//  ProjectsViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import UIKit

final class ProjectsViewController: UIViewController {

    var suitesAndCasesCompletion: (() -> Void)? = {}
    var suitesAndCaseData = [SuiteAndCaseData]()
    var viewModel: ProjectsViewModel = .init()
    
    // MARK: - UI
    private lazy var tableVw: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(ProjectTableViewCell.self, forCellReuseIdentifier: ProjectTableViewCell.cellId)
        tv.backgroundColor = .clear
        return tv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        viewModel.delegate = self
        
        view.backgroundColor = AppTheme.bgPrimaryColor
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewProject)
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        executeWithErrorHandling {
            try viewModel.fetchProjectsJSON()
        }
    }
    
    // MARK: - UI
    func setupTableView() {
        title = "Repository".localized
        
        tableVw.delegate = self
        tableVw.dataSource = self
        
        view.addSubview(tableVw)
        tableVw.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide.snp.edges)
        }
    }
    
    // MARK: - @objc funcs
    @objc func addNewProject() {
        let vc = CreatingProjectViewController(viewModel: .init())
        vc.createdProjectCallback = {
            self.executeWithErrorHandling {
                try self.viewModel.fetchProjectsJSON()
            }
        }
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}

// MARK: - UpdateTableViewProtocol
extension ProjectsViewController: UpdateTableViewProtocol {
    func updateTableView() {
        DispatchQueue.main.async {
            self.tableVw.reloadData()
        }
    }
}

// MARK: - NextViewControllerPusher
extension ProjectsViewController: NextViewControllerPusher {
    func pushToNextVC(to item: Int? = nil) {
        DispatchQueue.main.async {
            if let item = item {
                PROJECT_NAME = self.viewModel.projects[item].code
            }
            let vc = SuitesAndCasesTableViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource
extension ProjectsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.countOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProjectTableViewCell.cellId, for: indexPath) as? ProjectTableViewCell else { return UITableViewCell() }
        let project = viewModel.projects[indexPath.row]
        
        cell.configure(with: project)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        pushToNextVC(to: indexPath.row)
    }
}

// MARK: - UITableViewDelegate
extension ProjectsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.separatorInset = UIEdgeInsets(top: 0, left: 1, bottom: 2, right: -5)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let swipeAction = UIContextualAction(style: .destructive, title: "Delete") { action, view, completion in
            self.viewModel.deleteProject(at: indexPath.row)
        }
        return UISwipeActionsConfiguration(actions: [swipeAction])
    }
}
