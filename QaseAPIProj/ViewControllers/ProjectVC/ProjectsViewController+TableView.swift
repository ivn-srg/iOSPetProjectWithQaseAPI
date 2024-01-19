//
//  ProjectsViewController+TableView.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 19.01.2024.
//

import Foundation
import UIKit

extension ProjectsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func setupTableView() {
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
    
    func reloadTableView() {
        DispatchQueue.main.async {
            self.tableVw.reloadData()
        }
    }
    
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
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.separatorInset = UIEdgeInsets(top: 0, left: 1/*cell.bounds.size.width*/, bottom: 2, right: -5)
        
    }
}
