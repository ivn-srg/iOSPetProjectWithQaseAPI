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
    var projects: [Project] = [] {
        didSet {
            delegate?.updateTableView()
        }
    }
    private var totalCountOfProject: Int = 0
    private var hasMoreData = true
    private let realmDb = RealmManager.shared
    
    // MARK: - lifecycle
    init() {}
    
    // MARK: - Network funcs
    func fetchProjectsJSON(place: PlaceOfRequest = .start) throws {
        if hasMoreData {
            LoadingIndicator.startLoading()
            Task {
                if place == .start, let projects = realmDb.getProjects(), !projects.isEmpty {
                    self.projects = projects
                    LoadingIndicator.stopLoading()
                    return
                }
                guard let urlString = apiManager.formUrlString(
                    APIMethod: .project,
                    codeOfProject: nil,
                    limit: 20,
                    offset: projects.count,
                    parentSuite: nil,
                    caseId: nil
                ) else { return }
                
                
                let projectListResult = try await apiManager.performRequest(
                    from: urlString,
                    method: .get,
                    modelType: ProjectDataModel.self
                )
                
                let _ = realmDb.saveProjects(projectListResult.result.entities)
                
                projects.append(contentsOf: projectListResult.result.entities)
                totalCountOfProject = totalCountOfProject != 0 ? totalCountOfProject : projectListResult.result.total
                hasMoreData = totalCountOfProject > projects.count
                
                LoadingIndicator.stopLoading()
            }
        }
    }
    
    func deleteProject(at index: Int) throws(APIError) {
        guard let urlString = apiManager.formUrlString(
            APIMethod: .project,
            codeOfProject: self.projects[index].code,
            limit: nil,
            offset: nil,
            parentSuite: nil,
            caseId: nil
        ) else { throw .invalidURL }
        LoadingIndicator.startLoading()
        
        Task {
            let deletingResult = try await apiManager.performRequest(
                from: urlString,
                method: .delete,
                modelType: SharedResponseModel.self
            )
            if deletingResult.status {
                let deletedProject = projects.remove(at: index)
                let _ = realmDb.deleteProject(deletedProject)
                
            }
            LoadingIndicator.stopLoading()
        }
    }
    
    // MARK: - VC funcs
    func countOfRows() -> Int {
        projects.count
    }
}
