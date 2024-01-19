//
//  SuitesAndCasesTableViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 09.01.2024.
//

import UIKit


final class SuitesAndCasesTableViewController: UIViewController {
    
    var viewModel: SuitesAndCasesViewModel = SuitesAndCasesViewModel()
    
    var codeOfProject = ""
    var parentSuite: Int? = nil
    var suitesAndCaseData: [SuiteAndCaseData] = []
    
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
    
    // MARK: - Lifecycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        
        LoadingIndicator.stopLoading()
    }
    
    func bindViewModel() {
        viewModel.isLoadingData.bind { isLoading in
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
        
        viewModel.projects.bind { [weak self] projects in
            guard let self = self,
                  let projects = projects else {
                return
            }
            self.projectsDataSource = projects
            self.reloadTableView()
        }
    }

}

private extension SuitesAndCasesTableViewController {
    
    func setup() {
        
        title = viewModel.getSuiteTitle()
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
        emptyDataLabel.isHidden = viewModel.filteredData.count > 0
    }
}


// MARK: - Table view data source

extension SuitesAndCasesTableViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        updateEmptyDataLabelVisibility()
        return viewModel.filteredData.count > 0 ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        title
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.filteredData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SuitesAndCasesTableViewCell.cellId, for: indexPath) as? SuitesAndCasesTableViewCell else {
            return UITableViewCell()
        }
        
        let dataForCell = viewModel.filteredData[indexPath.row]
        cell.configure(with: dataForCell)
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if viewModel.filteredData[indexPath.row].isSuites {
            let vc = SuitesAndCasesTableViewController()
            vc.parentSuite = viewModel.filteredData[indexPath.row].id
            vc.suitesAndCaseData = viewModel.suitesAndCaseData
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            tableVw.reloadData()
        }
    }
}

extension SuitesAndCasesTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

