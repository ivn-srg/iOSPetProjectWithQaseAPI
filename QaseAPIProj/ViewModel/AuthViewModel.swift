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
            if let delegate = delegate {
                delegate.pushToNextVC(to: nil)
            }
        }
    }
    
    // MARK: - lifecycle
    
    init(delegate: NextViewControllerPusher? = nil) {
        self.delegate = delegate
    }
    
    func fetchProjectsJSON() {
        LoadingIndicator.startLoading()
        
        guard let urlString = Constants.getUrlString(
            APIMethod: .project,
            codeOfProject: nil,
            limit: 1,
            offset: 0,
            parentSuite: nil,
            caseId: nil
        ) else { return }
        
        DispatchQueue.global().async {
            APIManager.shared.fetchData(
                from: urlString,
                method: Constants.APIType.get.rawValue,
                modelType: ProjectDataModel.self)
            { [weak self] (result: Result<ProjectDataModel, Error>) in
                
                switch result {
                case .success(let jsonProjects):
                    self?.totalCountOfProject = jsonProjects.result.total
                    self?.authStatus = jsonProjects.status ? true : false
                case .failure(let error):
                    print(error)
                    DispatchQueue.main.async {
                        LoadingIndicator.stopLoading()
                    }
                }
            }
        }
    }
}
