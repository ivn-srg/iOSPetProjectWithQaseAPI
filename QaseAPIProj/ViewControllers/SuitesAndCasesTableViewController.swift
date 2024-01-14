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
        tv.register(SuitesAndCasesTableViewCell.self, forCellReuseIdentifier: SuitesAndCasesTableViewCell.cellId)
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
        
        tableVw.register(SuitesAndCasesTableViewCell.self, forCellReuseIdentifier: SuitesAndCasesTableViewCell.cellId)
        
        LoadingIndicator.stopLoading()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: SuitesAndCasesTableViewCell.cellId, for: indexPath) as! SuitesAndCasesTableViewCell
        
        let suite = suitesOfProject[indexPath.section]
        let testCasesInSuite = casesOfProject.filter( {$0.suiteId == suite.id} )
        let testCase = testCasesInSuite[indexPath.row]
        
        cell.configure(with: testCase)
    
        return cell
        
    }
    
}

extension SuitesAndCasesTableViewController {
    
    func setup() {
        
        navigationItem.title = "Test suites"
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
