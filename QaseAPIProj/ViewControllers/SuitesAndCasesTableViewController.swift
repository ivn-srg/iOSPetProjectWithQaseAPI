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
    
    let GroupSection = ["---","Описание","Ингредиенты","Как приготовить", "Пищевая ценность"]

    // Создаём массив с данными
    let itemsInfoArrays = [
    ["1111111111111111"],
    ["1.4","1.5","1.6"],
    ["22", "33"],
    ["6","7", "8"],
    ["26","27", "28"]
    ]
    
    // MARK: - UI
    
    private lazy var tableVw: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .white
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return tv
    }()
    
    // MARK: - Lifecycles

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        
        view.backgroundColor = .white
        
        tableVw.delegate = self
        tableVw.dataSource = self
        
        fetchSuitesJSON(Constants.TOKEN)
        fetchCasesJSON(Constants.TOKEN)
    }
    
    private func fetchSuitesJSON(_ token: String) {
        let urlString: String = "https://api.qase.io/v1/suite/\(codeOfProject)?limit=100&offset=0"
        
        // Создаем URL и URLRequest
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        
        // Устанавливаем HTTP метод
        request.httpMethod = "GET"
        
        // Устанавливаем свой заголовок
        request.addValue(token, forHTTPHeaderField: "Token")
        
        // Отправляем запрос
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Проверяем наличие ошибок
            if let error = error {
                DispatchQueue.main.async {
                    let ac = UIAlertController(title: "Something went wrong", message: "\(error)", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
            } else if let data = data {
                // Парсим ответ
                let decoder = JSONDecoder()
                do {
                    // Пробуем декодировать полученные данные
                    let jsonSuites = try decoder.decode(SuitesDataModel.self, from: data)
                    // Операции с результатами парсинга
                    self.suitesOfProject = jsonSuites.result.entities
                    
                    DispatchQueue.main.async {
                        self.tableVw.reloadData()
                    }
                    
                } catch {
                    print(response ?? "просто ответ", data, error)
                    DispatchQueue.main.async {
                        let ac = UIAlertController(title: "Server Error", message: "Invalid network response", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            }
        }
        task.resume()
    }
    
    private func fetchCasesJSON(_ token: String) {
        let urlString: String = "https://api.qase.io/v1/case/\(codeOfProject)?limit=100&offset=0"
        
        // Создаем URL и URLRequest
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        
        // Устанавливаем HTTP метод
        request.httpMethod = "GET"
        
        // Устанавливаем свой заголовок
        request.addValue(token, forHTTPHeaderField: "Token")
        
        // Отправляем запрос
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            // Проверяем наличие ошибок
            if let error = error {
                DispatchQueue.main.async {
                    let ac = UIAlertController(title: "Something went wrong", message: "\(error)", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(ac, animated: true)
                }
            } else if let data = data {
                // Парсим ответ
                let decoder = JSONDecoder()
                do {
                    // Пробуем декодировать полученные данные
                    let jsonSuites = try decoder.decode(TestCasesModel.self, from: data)
                    // Операции с результатами парсинга
                    self.casesOfProject = jsonSuites.result.entities
                    
                    DispatchQueue.main.async {
                        self.tableVw.reloadData()
                    }
                    
                } catch {
                    print(response ?? "просто ответ", data, error)
                    DispatchQueue.main.async {
                        let ac = UIAlertController(title: "Server Error", message: "Invalid network response", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            }
        }
        task.resume()
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
        print("rjkичество кейсов \(casesOfProject.filter( {$0.suite_id == suitesOfProject.filter( {$0.parent_id == nil} )[section].id} ).count)")
        return casesOfProject.filter( {$0.suite_id == suitesOfProject.filter( {$0.parent_id == nil} )[section].id} ).count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableVw.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let section = indexPath.section


        cell.textLabel?.text = casesOfProject.filter( {$0.suite_id == suitesOfProject.filter( {$0.parent_id == nil} )[section].id} )[indexPath.row].title
        return cell
    }

}


private extension SuitesAndCasesTableViewController {
    
    func setup() {
        
        title = "Test suites"
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
