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
            Task { @MainActor in
                self.delegate?.checkConditionAndToggleRightBarButton()
            }
        }
    }
    var isFieldsEmpty = false {
        didSet {
            Task { @MainActor in
                self.emptyFieldsClosure()
            }
        }
    }
    var isEntityWasCreated = false {
        didSet {
            Task { @MainActor in
                self.creatingFinishCallback()
            }
        }
    }
    var creatingFinishCallback: () -> Void = {}
    var emptyFieldsClosure: () -> Void = {}
    
    // MARK: - LifeCycle
    init() {
        self.creatingProject = .init()
    }
    
    // MARK: - Network work
    func createNewProject() async throws {
        if creatingProject.isEmpty {
            isFieldsEmpty = true
            return
        }
        guard let urlString = apiManager.formUrlString(
                                            APIMethod: .project,
                                            codeOfProject: nil,
                                            limit: nil,
                                            offset: nil,
                                            parentSuite: nil,
                                            caseId: nil
                                        ) else { return }
        LoadingIndicator.startLoading()
        
        let response = try await apiManager.performRequest(
            with: creatingProject,
            from: urlString,
            method: .post,
            modelType: ServerResponseModel<CreateOrUpdateProjectModel>.self
        )
        isEntityWasCreated = response.status.value
        LoadingIndicator.stopLoading()
    }
}
