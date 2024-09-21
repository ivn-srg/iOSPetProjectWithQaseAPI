//
//  CreatingProjectViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.09.2024.
//

import Foundation

final class CreatingProjectViewModel {
    // MARK: - Fields
    weak var delegate: CheckEnablingRBBProtocol?
    var creatingProject: CreatingProject {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.checkConditionAndToggleRightBarButton()
            }
        }
    }
    var isFieldsEmpty = false {
        didSet {
            DispatchQueue.main.async {
                self.emptyFieldsClosure()
            }
        }
    }
    var isEntityWasCreated = false {
        didSet {
            DispatchQueue.main.async {
                self.creatingFinishCallback()
            }
        }
    }
    var creatingFinishCallback: () -> Void = {}
    var emptyFieldsClosure: () -> Void = {}
    
    // MARK: - LifeCycle
    init() {
        self.creatingProject = CreatingProject(title: "", code: "", description: "")
    }
    
    // MARK: - Network work
    func createNewProject() {
        LoadingIndicator.startLoading()
        if creatingProject.isEmpty {
            isFieldsEmpty = true
            return
        }
        guard let urlString = Constants.getUrlString(
                                            APIMethod: .project,
                                            codeOfProject: nil,
                                            limit: nil,
                                            offset: nil,
                                            parentSuite: nil,
                                            caseId: nil
                                        ) else { return }
        APIManager.shared.createorUpdateEntity(
            newData: creatingProject,
            from: urlString,
            method: Constants.APIType.post.rawValue,
            modelType: ServerResponse<CreateOrUpdateProjectModel>.self) {
                [weak self] (result: Result<ServerResponse<CreateOrUpdateProjectModel>, Error>) in
            
            switch result {
            case .success(let jsonUpdateResult):
                self?.isEntityWasCreated = jsonUpdateResult.status
            case .failure(let error):
                print(error)
            }
            LoadingIndicator.stopLoading()
        }
    }
}
