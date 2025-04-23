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
    private var totalCountOfProjects = 0
    private var countOfFetchedProjects = 0
    private var hasMoreCases = true
    
    private let realmDb = RealmManager.shared
    
    // MARK: - lifecycle
    init() {}
    
    // MARK: - Network funcs
    func requestEntitiesData(place: PlaceOfRequest) async throws {
        switch place {
        case .start, .refresh:
            await MainActor.run {
                LoadingIndicator.startLoading()
            }
            
            resetPaginationArgs()
            loadCachedData()
            
            fallthrough
        case .continuos:
            do {
                try await fetchProjectsJSON()
            } catch {
                print("Error syncing data: \(error)")
            }
            
            await MainActor.run {
                LoadingIndicator.stopLoading()
            }
        }
    }
    
    private func fetchProjectsJSON() async throws {
        
        guard
            let urlString = apiManager.composeURL(for: .project, urlComponents: nil, queryItems: [
                .limit: 20, .offset: projects.count
            ])
        else { throw API.NetError.invalidURL }
        
        if hasMoreCases && !isLoading {
            isLoading = true
            
            let projectListResult = try await apiManager.performRequest(
                with: nil, from: urlString,
                method: .get,
                modelType: ProjectDataModel.self
            )
            
            let _ = realmDb.saveProjects(projectListResult.result.entities)
            
            projects.append(contentsOf: projectListResult.result.entities)
            totalCountOfProjects = totalCountOfProjects != 0
            ? totalCountOfProjects
            : projectListResult.result.total
            
            countOfFetchedProjects += Constants.LIMIT_OF_REQUEST
            hasMoreCases = countOfFetchedProjects < totalCountOfProjects

            isLoading = false
        }
    }
    
    private func loadCachedData() {
        if projects.isEmpty, let cashedProjects = realmDb.getProjects(), !cashedProjects.isEmpty {
            self.projects.append(contentsOf: cashedProjects)
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
    
    private func resetPaginationArgs() {
        totalCountOfProjects = 0
        countOfFetchedProjects = 0
        hasMoreCases = true
    }
    
    // MARK: - VC funcs
    func countOfRows() -> Int {
        projects.count
    }
}
