//
//  ProjectsViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import UIKit

class ProjectsViewController: UIViewController {
    
    // MARK: - UI
    
    private lazy var tableVw: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .clear
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 40
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return tv
    }()
    
    // MARK: - Lifecycle
    
    override func loadView() {
        super.loadView()
        setup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}

private extension ProjectsViewController {
    
    func setup() {
        
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
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        switch indexPath.row {
        case 0:
            cell.backgroundColor = .systemRed
        case 1:
            cell.backgroundColor = .systemBlue
        case 2:
            cell.backgroundColor = .systemCyan
        default:
            cell.backgroundColor = .systemPink
        }
        return cell
    }
    
    
}
