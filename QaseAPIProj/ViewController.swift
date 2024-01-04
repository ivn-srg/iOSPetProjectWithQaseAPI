//
//  ViewController.swift
//  project10
//
//  Created by Sergey Ivanov on 12.10.2023.
//

import UIKit

class ViewController: UITableViewController {
    enum Reason {
        case networkError
        case inputError
    }
    
    var websites = ["www.swift.org/blog/", "developer.apple.com/news/", "www.macrumors.com", "9to5mac.com"]
    let apiKey = "39c6765328aaa03935f70b3217b4df0d9434d4eb277c5586a7306c84db266de0"
    var petitions = [Petition]()
    var filteredPetitions = [Petition]()
    var searchText = " "
    var urlString = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        title = "Petitions"
        
        let infoButton = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(tapped))
        let searchBarButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchPetitions))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Open", style: .done, target: self, action: #selector(openTapped))
        
        navigationItem.leftBarButtonItems = [searchBarButton, infoButton]
        
        performSelector(inBackground: #selector(loadScreen), with: nil)
        
        self.refreshControl?.addTarget(self, action: #selector(refresh), for: .allEvents)
    }
    
    func submit(_ answer: String) {
        if answer.isEmpty {
            showError(Reason.inputError)
        } else {
            searchText = answer
            filteredPetitions = petitions.filter({$0.title.lowercased().contains(searchText.lowercased())})
            tableView.reloadData()
        }
    }

    func parse(json: Data) {
        let decoder = JSONDecoder()

        if let jsonPetitions = try? decoder.decode(Petitions.self, from: json) {
            petitions = jsonPetitions.results
            filteredPetitions = petitions.filter({$0.title.lowercased().contains(searchText.lowercased())})
            tableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: false)
        }
    }
    
    func showError(_ reason: Reason) {
        var title: String
        var message: String
        
        if reason == .networkError {
            title = "Loading error"
            message = "There was a problem loading the feed; please check your connection and try again."
        } else {
            title = "Input error"
            message = "There was a problem input the name of petition; please check your input."
        }
        
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(ac, animated: true)
        
    }
    
    // MARK: @objc methods
    
    @objc func openTapped() {
        let ac = UIAlertController(title: "Open page…", message: nil, preferredStyle: .actionSheet)
        for website in websites {
            ac.addAction(UIAlertAction(title: website, style: .default, handler: openPage))
        }
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
        present(ac, animated: true)
    }
    
    func openPage(action: UIAlertAction) {
        let url = URL(string: "https://" + action.title!)!
        webView.load(URLRequest(url: url))
    }
    
    @objc func refresh(sender:AnyObject) {
        // Updating your data here...
//        searchText = " "
        tableView.reloadData()
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let url = URL(string: self.urlString) {
                if let data = try? Data(contentsOf: url) {
                    // we're OK to parse!
                    self.parse(json: data)
                } else { self.showError(Reason.networkError) }
            } else { self.showError(Reason.networkError) }
        }
        self.refreshControl?.endRefreshing()
    }
    
    @objc func loadScreen() {
        searchText = " "
//        tableView.reloadData()
        if navigationController?.tabBarItem.tag == 0 {
            // urlString = "https://api.whitehouse.gov/v1/petitions.json?limit=100"
            urlString = "https://www.hackingwithswift.com/samples/petitions-1.json"
        } else {
            // urlString = "https://api.whitehouse.gov/v1/petitions.json?signatureCountFloor=10000&limit=100"
            urlString = "https://www.hackingwithswift.com/samples/petitions-2.json"
        }
        
        if let url = URL(string: self.urlString) {
            if let data = try? Data(contentsOf: url) {
                self.parse(json: data)
                return
            }
        }
        
        DispatchQueue.main.async {
            self.showError(.networkError)
        }
        
    }
    
    @objc func tapped() {
        let messageSource: String
        if navigationController?.tabBarItem.tag == 0 {
            messageSource = "https://www.hackingwithswift.com/samples/petitions-1.json"
        } else {
            messageSource = "https://www.hackingwithswift.com/samples/petitions-2.json"
        }
        let ac = UIAlertController(title: "Data source", message: "Data was taken from \(messageSource)", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    @objc func searchPetitions() {
        let ac = UIAlertController(title: "Search petition", message: "Start input a name of the petition", preferredStyle: .alert)
        ac.addTextField()
        ac.textFields?[0].text = searchText != " " ? searchText : ""
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak ac] action in
            guard let answer = ac?.textFields?[0].text else { return }
            self?.submit(answer)
        }
        
        let resetAction = UIAlertAction(title: "Reset", style: .destructive) { [weak self] action in
            self?.submit(" ")
        }
        
        ac.addAction(resetAction)
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    // MARK: main tableview methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("\(filteredPetitions.count) из \(petitions.count) and \(searchText)")

        return filteredPetitions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let petition = filteredPetitions[indexPath.row]
        
        cell.textLabel?.text = petition.title
        cell.detailTextLabel?.text = petition.body
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = DetailViewController()
        vc.detailItem = filteredPetitions[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

