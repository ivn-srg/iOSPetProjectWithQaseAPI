//
//  SuitesAndCasesTableViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 09.01.2024.
//

import UIKit

final class SuitesAndCasesTableViewController: UIViewController, UpdateTableViewProtocol {
    
    var viewModel: SuitesAndCasesViewModel
    
    // MARK: - UI
    
    private lazy var tableVw: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .white
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 44
        tv.register(SuitesAndCasesTableViewCell.self, forCellReuseIdentifier: SuitesAndCasesTableViewCell.cellId)
        return tv
    }()
    
    private let emptyDataLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "There's nothing here yet =("
        label.textAlignment = .center
        label.textColor = .gray
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    func showErrorAlert(titleAlert: String, messageAlert: String) {
        let ac = UIAlertController(title: titleAlert, message: messageAlert, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    // MARK: - Lifecycles
    
    init(parentSuite: Int? = nil) {
        self.viewModel = parentSuite != nil ? SuitesAndCasesViewModel(parentSuite: parentSuite) : SuitesAndCasesViewModel()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        
        viewModel.delegate = self
        viewModel.requestEntitiesData()
    }
    
    func updateTableView() {
        DispatchQueue.main.async {
            self.tableVw.reloadData()
            LoadingIndicator.stopLoading()
        }
    }
}

private extension SuitesAndCasesTableViewController {
    
    func setup() {
        
        title = viewModel.parentSuite == nil ? Constants.PROJECT_NAME : self.viewModel.suitesAndCaseData.filter( {$0.isSuites && $0.id == self.viewModel.parentSuite} ).first?.title
        navigationItem.largeTitleDisplayMode = .never
        
        view.backgroundColor = .white
        
        tableVw.delegate = self
        tableVw.dataSource = self
        
        view.addSubview(tableVw)
        tableVw.addSubview(emptyDataLabel)
        
        NSLayoutConstraint.activate([
            tableVw.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableVw.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableVw.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableVw.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            emptyDataLabel.centerYAnchor.constraint(equalTo: tableVw.centerYAnchor),
            emptyDataLabel.centerXAnchor.constraint(equalTo: tableVw.centerXAnchor),
        ])
    }
    
    private func updateEmptyDataLabelVisibility() {
        emptyDataLabel.isHidden = viewModel.suitesAndCaseData.count > 0
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SuitesAndCasesTableViewCell.cellId, for: indexPath) as? SuitesAndCasesTableViewCell else { return UITableViewCell() }
        
        let dataForCell = viewModel.suitesAndCaseData[indexPath.row]
        
        cell.configure(with: dataForCell)
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc: UIViewController
        if viewModel.suitesAndCaseData[indexPath.row].isSuites {
            vc = SuitesAndCasesTableViewController(parentSuite: viewModel.suitesAndCaseData[indexPath.row].id)
        } else {
            let viewModel = DetailTabbarControllerViewModel(caseId: viewModel.suitesAndCaseData[indexPath.row].id)
            vc = DetailTabBarController(vm: viewModel)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension SuitesAndCasesTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

