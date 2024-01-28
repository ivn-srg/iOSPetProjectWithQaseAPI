//
//  SuitesAndCasesTableViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 09.01.2024.
//

import UIKit


final class SuitesAndCasesTableViewController: UIViewController {
    
    var codeOfProject = ""
    var parentSuite: Int? = nil
    var suitesAndCaseData = [SuiteAndCaseData]() {
        didSet {
            if parentSuite == nil {
                filteredData = suitesAndCaseData.filter( {$0.parent_id == nil && $0.suiteId == nil} )
                
            } else {
                filteredData = suitesAndCaseData.filter( {$0.parent_id == self.parentSuite || $0.suiteId == self.parentSuite} )
            }
        }
    }
    
    var filteredData = [SuiteAndCaseData]()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        
        LoadingIndicator.stopLoading()
    }
}

private extension SuitesAndCasesTableViewController {
    
    func setup() {
        
        title = parentSuite == nil ? codeOfProject : self.suitesAndCaseData.filter( {$0.isSuites && $0.id == self.parentSuite} ).first?.title
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
        emptyDataLabel.isHidden = filteredData.count > 0
    }
}


// MARK: - Table view data source

extension SuitesAndCasesTableViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        updateEmptyDataLabelVisibility()
        return filteredData.count > 0 ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        title
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SuitesAndCasesTableViewCell.cellId, for: indexPath) as! SuitesAndCasesTableViewCell
        
        let dataForCell = filteredData[indexPath.row]
        
        cell.configure(with: dataForCell)
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if filteredData[indexPath.row].isSuites {
            let vc = SuitesAndCasesTableViewController()
            vc.parentSuite = filteredData[indexPath.row].id
            vc.suitesAndCaseData = self.suitesAndCaseData
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = DetailTabBarController()
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension SuitesAndCasesTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

