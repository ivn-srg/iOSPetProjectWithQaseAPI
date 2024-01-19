//
//  ProjectsViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 17.01.2024.
//

import Foundation
import UIKit

class ProjectsViewModel {
    
    var isLoadingData: Observable<Bool> = Observable(false)
    var dataSource: ProjectDataModel?
    var projects: Observable<[ProjectTableCellViewModel]> = Observable(nil)
    
    // MARK: - Network work
    
    func updateDataSource() {
        if isLoadingData.value ?? true {
            return
        }
        let limit = 100
        var offset = 0
        var totalCount = 0
        
        func fetchProjectsJSON(_ token: String, limit: Int, Offset: Int) {
            let urlString = Constants.urlString(Constants.APIMethods.project.rawValue, nil, limit, Offset)
            
            isLoadingData.value = true
            APIManager.shared.fetchData(from: urlString, method: Constants.APIType.get.rawValue, token: token, modelType: ProjectDataModel.self) { [weak self] (result: Result<ProjectDataModel, Error>) in
                self?.isLoadingData.value = false
                
                switch result {
                case .success(let jsonProjects):
                    self?.dataSource = jsonProjects
                    self?.mapProjectData()
                    
                    if offset == 0 {
                        totalCount = jsonProjects.result.total
                    }
                    
//                    DispatchQueue.main.async {
//                        LoadingIndicator.stopLoading()
//                    }
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
        
        fetchProjectsJSON(Constants.TOKEN, limit: limit, Offset: offset)
    }
    
    private func mapProjectData() {
        projects.value = self.dataSource?.result.entities.compactMap({ProjectTableCellViewModel(project: $0)})
    }
    
    // MARK: - Routing
    
    func navigateTo(_ row: Int) {
        
    }
    
    // MARK: - VC func
    
    func numberOfRows() -> Int {
        dataSource?.result.entities.count ?? 0
    }
}
