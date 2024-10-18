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
        guard let urlString = apiManager.formUrlString(
                                            APIMethod: .project,
                                            codeOfProject: nil,
                                            limit: totalCountOfProjects,
                                            offset: 0,
                                            parentSuite: nil,
                                            caseId: nil
                                        ) else { return }
        LoadingIndicator.startLoading()
        
        Task {
            let projectListResult = try await apiManager.performRequest(
                from: urlString,
                method: .get,
                modelType: ProjectDataModel.self
            )
            projects = projectListResult.result.entities
            LoadingIndicator.stopLoading()
        }
    }
    
    func deleteProject(at index: Int) {
        guard let urlString = apiManager.formUrlString(
                                            APIMethod: .project,
                                            codeOfProject: self.projects[index].code,
                                            limit: nil,
                                            offset: nil,
                                            parentSuite: nil,
                                            caseId: nil
                                        ) else { return }
        LoadingIndicator.startLoading()
        
        Task {
            let deletingResult = try await apiManager.performRequest(
                from: urlString,
                method: .delete,
                modelType: SharedResponseModel.self
            )
            if deletingResult.status {
                projects.remove(at: index)
            }
            LoadingIndicator.stopLoading()
        }
    }
    
    // MARK: - VC funcs
    
    func countOfRows() -> Int {
        projects.count
    }
}
