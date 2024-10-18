//
//  AuthViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 03.05.2024.
//

import Foundation

final class AuthViewModel {
    
    // MARK: - Fields
    var delegate: NextViewControllerPusher?
    var totalCountOfProject = 0
    var authStatus: Bool? = nil {
        didSet {
            delegate?.pushToNextVC(to: nil)
        }
    }
    
    // MARK: - lifecycle
    init(delegate: NextViewControllerPusher? = nil) {
        self.delegate = delegate
    }
    
    // MARK: - Network work
    func fetchProjectsJSON() {
        guard let urlString = apiManager.formUrlString(
            APIMethod: .project,
            codeOfProject: nil,
            limit: 1,
            offset: 0,
            parentSuite: nil,
            caseId: nil
        ) else { return }
        LoadingIndicator.startLoading()
        
        Task {
            let projectData = try await apiManager.performRequest(
                from: urlString,
                method: .get,
                modelType: ProjectDataModel.self
            )
            totalCountOfProject = projectData.result.total
            authStatus = projectData.status
            LoadingIndicator.stopLoading()
        }
    }
}
