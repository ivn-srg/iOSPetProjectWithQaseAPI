//
//  ProjectListViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 03.05.2024.
//

import Foundation


final class ProjectsViewModel {
    // MARK: - Fields
    weak var delegate: UpdateTableViewProtocol?
    var totalCountOfProjects: Int = 0
    var projects: [Project] = [] {
        didSet {
            delegate?.updateTableView()
        }
    }
    
    // MARK: - lifecycle
    init() {}
    
    // MARK: - Network funcs
    func fetchTotalCountOfProjects() async throws {
        guard let urlString = apiManager.formUrlString(
            APIMethod: .project,
            codeOfProject: nil,
            limit: 1,
            offset: 0,
            parentSuite: nil,
            caseId: nil
        ) else { return }
        
        let projectData = try await apiManager.performRequest(
            from: urlString,
            method: .get,
            modelType: ProjectDataModel.self
        )
        totalCountOfProjects = projectData.result.total
    }
    
    func fetchProjectsJSON() throws {
        LoadingIndicator.startLoading()
        Task {
            try await fetchTotalCountOfProjects()
            
            guard let urlString = apiManager.formUrlString(
                APIMethod: .project,
                codeOfProject: nil,
                limit: totalCountOfProjects,
                offset: 0,
                parentSuite: nil,
                caseId: nil
            ) else { return }
            
            
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
