//
//  ProjectsViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import UIKit

final class ProjectsViewController: UIViewController {
    
    var suitesAndCasesCompletion: (() -> Void)? = {}
    var viewModel: ProjectsViewModel = .init()
    
    // MARK: - UI
    private lazy var tableVw: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(ProjectTableViewCell.self, forCellReuseIdentifier: ProjectTableViewCell.cellId)
        tv.backgroundColor = .clear
        tv.accessibilityIdentifier = "projectsTableView"
        return tv
    }()
    
    private lazy var rightBarButton: UIBarButtonItem = {
        let rbb = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewProject)
        )
        rbb.accessibilityIdentifier = "addNewProjectRBB"
        return rbb
    }()
    
    private lazy var emptyDataLabel: UILabel = EmptyDataLabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        viewModel.delegate = self
        configureRefreshControl()
        
        view.backgroundColor = AppTheme.bgPrimaryColor
        navigationItem.rightBarButtonItem = rightBarButton
        navigationController?.navigationBar.accessibilityIdentifier = "navigationBar"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        executeWithErrorHandling { [weak self] in
            try await self?.viewModel.requestEntitiesData(place: .start)
        }
    }
    
    // MARK: - UI
    func setupTableView() {
        title = "Repository".localized
        
        tableVw.delegate = self
        tableVw.dataSource = self
        
        view.addSubview(emptyDataLabel)
        emptyDataLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        view.addSubview(tableVw)
        tableVw.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide.snp.edges)
        }
    }
    
    private func updateEmptyDataLabelVisibility() {
        emptyDataLabel.isHidden = viewModel.countOfRows() > 0
    }
    
    // MARK: - @objc func for navigation
    @objc func addNewProject() {
        let vc = CreatingProjectViewController(viewModel: .init())
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}

// MARK: - UpdateTableViewProtocol
extension ProjectsViewController: UpdateTableViewProtocol {
    func updateTableView() {
        Task { @MainActor in tableVw.reloadData() }
    }
}

// MARK: - NextViewControllerPusher
extension ProjectsViewController: NextViewControllerPusher {
    func pushToNextVC(to item: Int? = nil) {
        Task { @MainActor in
            if let item = item {
                PROJECT_NAME = viewModel.projects[item].code
            }
            let vc = TestEntitiesTableViewController()
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource
extension ProjectsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        updateEmptyDataLabelVisibility()
        return viewModel.countOfRows()
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
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let swipeAction = UIContextualAction(style: .destructive, title: "Delete".localized) { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            let codeOfProject = viewModel.projects[indexPath.row].code
            let composedMessage = String(format: "confirmMessage".localized, "Project".localized.lowercased(), codeOfProject)
            
            UIAlertController.showConfirmAlert(
                on: self,
                title: "Confirmation".localized,
                message: composedMessage) { _ in
                    self.executeWithErrorHandling {
                        try await self.viewModel.deleteProject(at: indexPath.row)
                    }
                    completionHandler(true)
                } cancelCompetionHandler: { _ in
                    completionHandler(false)
                }
        }
        swipeAction.image = AppTheme.trashImage
        return UISwipeActionsConfiguration(actions: [swipeAction])
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.separatorInset = UIEdgeInsets(top: 0, left: 1, bottom: 2, right: -5)
        
        if viewModel.projects.count - indexPath.row <= 3 && !viewModel.isLoading {
            executeWithErrorHandling { [weak self] in
                try await self?.viewModel.requestEntitiesData(place: .continuos)
            }
        }
    }
}

extension ProjectsViewController {
    func configureRefreshControl() {
        tableVw.refreshControl = UIRefreshControl()
        tableVw.refreshControl?.addTarget(self,
                                          action: #selector(handleRefreshControl),
                                          for: .valueChanged)
    }
    
    @objc func handleRefreshControl() {
        executeWithErrorHandling { [weak self] in
            try await self?.viewModel.requestEntitiesData(place: .refresh, )
        }
        
        Task { @MainActor in
            self.tableVw.refreshControl?.endRefreshing()
        }
    }
}
