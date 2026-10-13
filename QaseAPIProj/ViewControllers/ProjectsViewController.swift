//
//  ProjectsViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import UIKit

final class ProjectsViewController: UIViewController {

    var onSelectProject: ((Project) -> Void)?
    var beforeDeleteProject: ((Project) async -> Bool)?
    var onProjectDeleted: ((String) -> Void)?
    var onProjectsChanged: (() -> Void)?
    var suitesAndCasesCompletion: (() -> Void)? = {}
    private var isVisible = false
    private var loadTask: Task<Void, Never>?
    private let viewModel: ProjectsViewModel
    private let onCreateProject: () -> Void

    init(viewModel: ProjectsViewModel, onCreateProject: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onCreateProject = onCreateProject
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - UI
    private lazy var tableVw: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(ProjectTableViewCell.self, forCellReuseIdentifier: ProjectTableViewCell.cellId)
        tv.backgroundColor = .clear
        tv.accessibilityIdentifier = AccessibilityID.projectsTableView.identifier
        return tv
    }()

    private lazy var rightBarButton: UIBarButtonItem = {
        let rbb = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewProject)
        )
        rbb.accessibilityIdentifier = AccessibilityID.addNewProjectRBB.identifier
        return rbb
    }()

    private lazy var searchController: UISearchController = {
        let search = UISearchController(searchResultsController: nil)
        search.searchBar.placeholder = "Search repository".localized
        search.obscuresBackgroundDuringPresentation = false
        search.definesPresentationContext = true
        return search
    }()

    private lazy var emptyDataLabel: UILabel = EmptyDataLabel()
    private let activity = UIActivityIndicatorView(style: .medium)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        viewModel.delegate = self
        configureRefreshControl()

        navigationItem.searchController = searchController
        definesPresentationContext = true
        navigationItem.rightBarButtonItem = rightBarButton

        if #available(iOS 26.0, *) {
            navigationItem.searchBarPlacementAllowsToolbarIntegration = false
        }

        view.backgroundColor = AppTheme.Palette.canvas
        navigationController?.navigationBar.accessibilityIdentifier = AccessibilityID.navigationBar.identifier
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isVisible = true

        loadTask?.cancel()
        viewModel.cancelLoading()
        loadTask = executeWithErrorHandling { [weak self] in
            try await self?.viewModel.requestEntitiesData(place: .start)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isVisible = false
        loadTask?.cancel()
        viewModel.cancelLoading()
    }

    deinit { loadTask?.cancel() }

    // MARK: - UI
    func setupTableView() {
        title = "Repository".localized

        tableVw.delegate = self
        tableVw.dataSource = self

        view.addSubview(activity)
        activity.snp.makeConstraints { $0.center.equalToSuperview() }
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
        emptyDataLabel.isHidden = viewModel.countOfRows() > 0 || viewModel.isLoading
    }

    // MARK: - @objc func for navigation
    @objc func addNewProject() {
        onCreateProject()
    }
}

// MARK: - UpdateTableViewProtocol
extension ProjectsViewController: UpdateTableViewProtocol {
    func updateTableView() {
        tableVw.reloadData()
        if viewModel.isLoading { activity.startAnimating() } else { activity.stopAnimating() }
        if !viewModel.isLoading { tableVw.refreshControl?.endRefreshing() }
    }
}

// MARK: - NextViewControllerPusher
extension ProjectsViewController: NextViewControllerPusher {
    func pushToNextVC(to item: Int? = nil) {
        guard let item, viewModel.projects.indices.contains(item) else { return }
        onSelectProject?(viewModel.projects[item])
    }
}

// MARK: - UITableViewDataSource
extension ProjectsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        updateEmptyDataLabelVisibility()
        return viewModel.countOfRows()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ProjectTableViewCell.cellId,
            for: indexPath
        ) as? ProjectTableViewCell else { return UITableViewCell() }
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
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let swipeAction = UIContextualAction(
            style: .destructive,
            title: "Delete".localized
        ) { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            guard self.viewModel.projects.indices.contains(indexPath.row)
            else { completionHandler(false)
                return }
            let project = self.viewModel.projects[indexPath.row]
            let codeOfProject = project.code
            let composedMessage = String(
                format: "confirmMessage".localized,
                "Project".localized.lowercased(),
                codeOfProject
            )

            UIAlertController.showConfirmAlert(
                on: self,
                title: "Confirmation".localized,
                message: composedMessage
            ) { _ in
                self.executeWithErrorHandling {
                    if let guardDelete = self.beforeDeleteProject,
                       !(await guardDelete(project)) { return }
                    try await self.viewModel.deleteProject(project)
                    self.onProjectDeleted?(project.code)
                    self.onProjectsChanged?()
                }
                completionHandler(true)
            } cancelCompetionHandler: { _ in
                completionHandler(false)
            }
        }
        swipeAction.image = AppImages.trash
        return UISwipeActionsConfiguration(actions: [swipeAction])
    }

    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        cell.separatorInset = UIEdgeInsets(top: 0, left: AppTheme.Space.regular, bottom: 0, right: 0)

        if isVisible && viewModel.projects.count - indexPath.row <= PaginationPolicy
            .prefetchThreshold && !viewModel
            .isLoading {
            loadTask?.cancel()
            viewModel.cancelLoading()
            loadTask = executeWithErrorHandling { [weak self] in
                try await self?.viewModel.requestEntitiesData(place: .continuos)
            }
        }
    }
}

extension ProjectsViewController {
    func configureRefreshControl() {
        tableVw.refreshControl = UIRefreshControl()
        tableVw.refreshControl?.addTarget(
            self,
            action: #selector(handleRefreshControl),
            for: .valueChanged
        )
    }

    @objc func handleRefreshControl() {
        loadTask?.cancel()
        viewModel.cancelLoading()
        loadTask = executeWithErrorHandling { [weak self] in
            try await self?.viewModel.requestEntitiesData(place: .refresh,)
        }

    }
}
