//
//  ProjectListViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 03.05.2024.
//

import Foundation


final class ProjectsViewModel {
    // MARK: - Fields
    var delegate: UpdateTableViewProtocol?
    let totalCountOfProjects: Int
    var projects: [Project] = [] {
        didSet {
            if let delegate = delegate {
                delegate.updateTableView()
            }
        }
    }
    
    // MARK: - lifecycle
    
    init(delegate: UpdateTableViewProtocol? = nil, totalCountOfProjects: Int) {
        self.delegate = delegate
        self.totalCountOfProjects = totalCountOfProjects
    }
    
    func fetchProjectsJSON() {
        LoadingIndicator.startLoading()
        
        guard let urlString = Constants.urlString(Constants.APIMethods.project, nil, totalCountOfProjects, 0, nil, nil) else { return }
        APIManager.shared.fetchData(from: urlString, method: Constants.APIType.get.rawValue, token: Constants.TOKEN, modelType: ProjectDataModel.self) { [weak self] (result: Result<ProjectDataModel, Error>) in
            
            switch result {
            case .success(let jsonProjects):
                if jsonProjects.status {
                    self?.projects = jsonProjects.result.entities
                }
            case .failure(let error):
                print(error)
                DispatchQueue.main.async {
                    LoadingIndicator.stopLoading()
                }
            }
        }
    }
    
    // MARK: - VC funcs
    
    func countOfRows() -> Int {
        projects.count
    }
}
