//
//  ProjectsViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 17.01.2024.
//

import Foundation
import UIKit

class ProjectsViewModel {
    
    weak var navigationController: UINavigationController?
    
    var onRowChange: ((Int) -> Void)?
    
    private var tapCount: Int = 0
    private var dataSource: [Project] = []
    
    // MARK: - Network work
    
    func updateDataSource() {
        let limit = 100
        var offset = 0
        var totalCount = 0
        
        func fetchProjectsJSON(_ token: String, limit: Int, Offset: Int) {
            let urlString = Constants.urlString(Constants.APIMethods.project.rawValue, nil, limit, Offset)
            
            APIManager.shared.fetchData(from: urlString, method: Constants.APIType.get.rawValue, token: token, modelType: ProjectDataModel.self) { [weak self] (result: Result<ProjectDataModel, Error>) in
                
                switch result {
                case .success(let jsonProjects):
                    self?.dataSource += jsonProjects.result.entities
                    
                    if offset == 0 {
                        totalCount = jsonProjects.result.total
                    }
                    offset += self?.dataSource.count ?? 0
                    
                    DispatchQueue.main.async {
                        LoadingIndicator.stopLoading()
                    }
                case .failure(let error):
                    if let apiError = error as? APIError, apiError == .invalidURL {
                        DispatchQueue.main.async {
                            LoadingIndicator.stopLoading()
                            //                            self?.showErrorAlert(titleAlert: "Error", messageAlert: "Invalid URL")
                        }
                    } else {
                        DispatchQueue.main.async {
                            LoadingIndicator.stopLoading()
//                                                        self?.showErrorAlert(titleAlert: "Something went wrong", messageAlert: "\(error)")
                        }
                    }
                }
            }
        }
        
        LoadingIndicator.startLoading()
        
        repeat {
            fetchProjectsJSON(Constants.TOKEN, limit: limit, Offset: offset)
        } while totalCount > offset
        
        LoadingIndicator.stopLoading()
    }
    
    // MARK: - Routing
    
    func inject(navigation: UINavigationController) {
        navigationController = navigation
    }
    
    func navigateTo(_ row: Int) {
        
    }
    
    // MARK: - VC func
    
    func numberOfRows() -> Int {
        dataSource.count
    }
    
    func cell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProjectTableViewCell.cellId, for: indexPath) as! ProjectTableViewCell
        let data = dataSource[indexPath.row]
        
        cell.configure(with: data)
        
        return cell
    }
}
