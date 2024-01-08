//
//  ProjectsViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 05.01.2024.
//

import UIKit

class ProjectsViewController: UIViewController {
    
    var projects = [Entity]()
    var TOKEN = ""
    
    // MARK: - UI
    
    private lazy var tableVw: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .white
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tv.register(ProjectTableViewCell.self, forCellReuseIdentifier: ProjectTableViewCell.cellId)
        return tv
    }()
    
    // MARK: - Lifecycle
    
    override func loadView() {
        super.loadView()
        setup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        tableVw.delegate = self
        tableVw.dataSource = self
        
        performSelector(inBackground: #selector(fetchJSON), with: nil)
    }
    
    @objc func fetchJSON() {
        let urlString: String = "https://api.qase.io/v1/project?limit=10&offset=0"
        
        // Создаем URL и URLRequest
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        
        // Устанавливаем HTTP метод
        request.httpMethod = "GET"
        
        // Устанавливаем свой заголовок
        request.addValue(TOKEN, forHTTPHeaderField: "Token")
        
        // Отправляем запрос
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Проверяем наличие ошибок
            if let error = error {
                let ac = UIAlertController(title: "Something went wrong", message: "\(error)", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(ac, animated: true)
            } else if let data = data {
                // Парсим ответ
                let decoder = JSONDecoder()
                do {
                    // Пробуем декодировать полученные данные
                    let jsonProjects = try decoder.decode(DataModel.self, from: data)
                    // Операции с результатами парсинга
                    self.projects = jsonProjects.result.entities
                    DispatchQueue.main.async {
                        self.tableVw.reloadData() // Обновляем интерфейс на главной очереди
                    }
                } catch {
                    let ac = UIAlertController(title: "Server Error", message: "Invalid network response", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
            }
        }
        task.resume()
    }
}

private extension ProjectsViewController {
    
    func setup() {
        
        title = "Projects"
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

// MARK: - UITableViewDataSource

extension ProjectsViewController: UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(projects.count)
        return projects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProjectTableViewCell.cellId, for: indexPath) as! ProjectTableViewCell
        let project = projects[indexPath.row]
        
        cell.configure(
            nameOfProject: project.title,
            codeOfProject: project.code,
            numberOfTest: project.counts.cases,
            numberOfSuites: project.counts.suites,
            numOfActiveRuns: project.counts.runs.active
        )
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ProjectsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        cell.separatorInset = UIEdgeInsets(top: 0, left: 1/*cell.bounds.size.width*/, bottom: 2, right: -5)
        
    }
}
