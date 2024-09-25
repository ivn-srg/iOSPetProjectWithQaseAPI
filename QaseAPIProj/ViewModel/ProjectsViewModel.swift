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
            delegate?.updateTableView()
        }
    }
    
    // MARK: - lifecycle
    
    init(delegate: UpdateTableViewProtocol? = nil, totalCountOfProjects: Int) {
        self.delegate = delegate
        self.totalCountOfProjects = totalCountOfProjects
    }
    
    func fetchProjectsJSON() {
        LoadingIndicator.startLoading()
        
        guard let urlString = Constants.getUrlString(
                                            APIMethod: .project,
                                            codeOfProject: nil,
                                            limit: totalCountOfProjects,
                                            offset: 0,
                                            parentSuite: nil,
                                            caseId: nil
                                        ) else { return }
        APIManager.shared.fetchData(from: urlString, method: Constants.APIType.get.rawValue, modelType: ProjectDataModel.self) { [weak self] (result: Result<ProjectDataModel, Error>) in
            
            switch result {
            case .success(let jsonProjects):
                if jsonProjects.status {
                    self?.projects = jsonProjects.result.entities
                }
            case .failure(let error):
                print(error)
            }
            
            LoadingIndicator.stopLoading()
        }
    }
    
    func deleteProject(at index: Int) {
        LoadingIndicator.startLoading()
        
        guard let urlString = Constants.getUrlString(
                                            APIMethod: .project,
                                            codeOfProject: self.projects[index].code,
                                            limit: nil,
                                            offset: nil,
                                            parentSuite: nil,
                                            caseId: nil
                                        ) else { return }
        APIManager.shared.fetchData(
            from: urlString,
            method: Constants.APIType.delete.rawValue,
            modelType: SharedResponseModel.self)
        {
            [weak self] (result: Result<SharedResponseModel, Error>) in
            
            switch result {
            case .success(let jsonResult):
                if jsonResult.status {
                    self?.projects.remove(at: index)
                }
            case .failure(let error):
                print(error)
            }
            LoadingIndicator.stopLoading()
        }
    }
    
    // MARK: - VC funcs
    
    func countOfRows() -> Int {
        projects.count
    }
}
