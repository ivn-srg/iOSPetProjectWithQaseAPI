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
    var isLoading = false
    private var totalCountOfProject: Int = 0
    private var hasMoreData = true
    private let realmDb = RealmManager.shared
    
    // MARK: - lifecycle
    init() {}
    
    // MARK: - Network funcs
    func fetchProjectsJSON(place: PlaceOfRequest = .start) async throws {
        if hasMoreData {
            LoadingIndicator.startLoading()
            isLoading = true
            
            if place == .start && projects.isEmpty, let cashedProjects = realmDb.getProjects(), !cashedProjects.isEmpty {
                self.projects.append(contentsOf: cashedProjects)
                LoadingIndicator.stopLoading()
                isLoading = false
                return
            }
            
            guard
                let urlString = apiManager.composeURL(for: .project, urlComponents: nil, queryItems: [
                    .limit: 20, .offset: projects.count
                ])
            else { throw API.NetError.invalidURL }
            
            do {
                let projectListResult = try await apiManager.performRequest(
                    with: nil, from: urlString,
                    method: .get,
                    modelType: ProjectDataModel.self
                )
                
                let _ = realmDb.saveProjects(projectListResult.result.entities)
                
                projects.append(contentsOf: projectListResult.result.entities)
                totalCountOfProject = totalCountOfProject != 0 ? totalCountOfProject : projectListResult.result.total
                hasMoreData = totalCountOfProject > projects.count
                
                LoadingIndicator.stopLoading()
                isLoading = false
            } catch {
                LoadingIndicator.stopLoading()
                throw error
            }
        }
    }
    
    func deleteProject(at index: Int) async throws(API.NetError) {
        
        guard
            let urlString = apiManager.composeURL(for: .project, urlComponents: [projects[index].code], queryItems: nil)
        else { throw .invalidURL }
        
        LoadingIndicator.startLoading()
        
        let deletingResult = try await apiManager.performRequest(
            with: nil, from: urlString,
            method: .delete,
            modelType: SharedResponseModel.self
        )
        
        if deletingResult.status {
            let deletedProject = projects.remove(at: index)
            let _ = realmDb.deleteProject(deletedProject)
            
        }
        
        LoadingIndicator.stopLoading()
    }
    
    // MARK: - VC funcs
    func countOfRows() -> Int {
        projects.count
    }
}
