//
//  SuitesAndCasesTableViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 09.01.2024.
//

import UIKit

final class SuitesAndCasesTableViewController: UIViewController {

    var viewModel: SuitesAndCasesViewModel
    
    // MARK: - UI
    
    private lazy var tableVw: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 44
        tv.register(SuitesAndCasesTableViewCell.self, forCellReuseIdentifier: SuitesAndCasesTableViewCell.cellId)
        return tv
    }()
    
    private let emptyDataLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "There's nothing here yet 🙁".localized
        label.textAlignment = .center
        label.textColor = .gray
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    // MARK: - Lifecycles
    
    init(parentSuite: ParentSuite? = nil) {
        viewModel = parentSuite != nil ? SuitesAndCasesViewModel(parentSuite: parentSuite) : SuitesAndCasesViewModel()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.delegate = self
        setupTableView()
        configureRefreshControls()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewEntity))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        executeWithErrorHandling {
            try await self.viewModel.requestEntitiesData()
        }
    }
    
    // MARK: - Setuping UI for tableView
    func setupTableView() {
        view.backgroundColor = AppTheme.bgPrimaryColor
        title = viewModel.parentSuite == nil ? PROJECT_NAME
        : self.viewModel.suitesAndCaseData.filter( {$0.isSuite && $0.id == self.viewModel.parentSuite?.id} ).first?.title
        
        tableVw.delegate = self
        tableVw.dataSource = self
        
        view.addSubview(tableVw)
        tableVw.addSubview(emptyDataLabel)
        
        tableVw.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide.snp.edges)
        }
        emptyDataLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    private func updateEmptyDataLabelVisibility() {
        emptyDataLabel.isHidden = viewModel.countOfRows() > 0
    }
    
    // MARK: - @objc funcs
    @objc func addNewEntity() {
        let vc = CreateSuiteOrCaseViewController(viewModel: .init(parentSuiteId: viewModel.parentSuite?.id))
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}

// MARK: - UpdateTableViewProtocol
extension SuitesAndCasesTableViewController: UpdateTableViewProtocol {
    func updateTableView() {
        Task { @MainActor in
            tableVw.reloadData()
        }
    }
}

// MARK: - NextViewControllerPusher
extension SuitesAndCasesTableViewController: NextViewControllerPusher {
    func pushToNextVC(to item: Int?) {
        guard let item = item else { return }
        
        let vc: UIViewController
        let testEntityItem = viewModel.suitesAndCaseData[item]
        let parentSuite = ParentSuite(id: testEntityItem.id, title: testEntityItem.title, codeOfProject: PROJECT_NAME)
        let caseItem = viewModel.suitesAndCaseData[item]
        
        if testEntityItem.isSuite {
            vc = SuitesAndCasesTableViewController(parentSuite: parentSuite)
        } else {
            vc = TestCaseViewController(caseId: caseItem.id)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Table view data source
extension SuitesAndCasesTableViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        updateEmptyDataLabelVisibility()
        return viewModel.suitesAndCaseData.count > 0 ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        title
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.countOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SuitesAndCasesTableViewCell.cellId,
            for: indexPath) as? SuitesAndCasesTableViewCell
        else { return UITableViewCell() }
        
        let dataForCell = viewModel.suitesAndCaseData[indexPath.row]
        cell.configure(with: dataForCell)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        pushToNextVC(to: indexPath.row)
    }
}

// MARK: - Table view delegate
extension SuitesAndCasesTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let swipeAction = UIContextualAction(style: .destructive, title: "Delete".localized) { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            let entity = viewModel.suitesAndCaseData[indexPath.row]
            let entityName = entity.isSuite ? "Test suite".localized : "Test case".localized
            let composedMessage = String(format: "confirmMessage".localized, entityName.localized.lowercased(), "")
            
            UIAlertController.showConfirmAlert(
                on: self,
                title: "Confirmation".localized,
                message: composedMessage) { _ in
                    self.executeWithErrorHandling {
                        try await self.viewModel.deleteEntity(at: indexPath.row)
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
        if viewModel.suitesAndCaseData.count - indexPath.row <= 3 && !viewModel.isLoading {
            executeWithErrorHandling {
                try await self.viewModel.requestEntitiesData(place: .continuos)
            }
        }
    }
}

extension SuitesAndCasesTableViewController {
    func configureRefreshControls() {
        tableVw.refreshControl = UIRefreshControl()
        tableVw.refreshControl?.addTarget(self,
                                          action: #selector(handleRefreshControl),
                                          for: .valueChanged)
        
        
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        tableVw.tableFooterView = activityIndicatorView
    }
    
    @objc func handleRefreshControl() {
        executeWithErrorHandling {
            try await self.viewModel.requestEntitiesData()
        }
        
        tableVw.refreshControl?.endRefreshing()
    }
}
