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
                delegate?.checkConditionAndToggleRightBarButton()
            }
        }
    }
    var isFieldsEmpty = false {
        didSet {
            if isFieldsEmpty {
                Task { @MainActor in
                    showErrorClosure(
                        "Not enough".localized,
                        "Probably you didn't fill all fields, check it, please".localized
                    )
                }
            }
        }
    }
    var isEntityWasCreated = false {
        didSet {
            Task { @MainActor in
                if isEntityWasCreated {
                    creatingFinishCallback()
                } else {
                    showErrorClosure("Error".localized, "Something went wrong".localized)
                }
            }
        }
    }
    var creatingFinishCallback: () -> Void = {}
    var showErrorClosure: (String, String) -> Void = { (_,_) in }
    
    // MARK: - LifeCycle
    init() {
        self.creatingProject = .init()
    }
    
    // MARK: - Network work
    func createNewProject() async throws(API.NetError) {
        if creatingProject.isEmpty {
            isFieldsEmpty = true
            return
        }
        
        guard let urlString = apiManager.composeURL(for: .project, urlComponents: nil, queryItems: nil) else { throw .invalidURL }
        
        LoadingIndicator.startLoading()
        
        let response = try await apiManager.performRequest(
            with: creatingProject,
            from: urlString,
            method: .post,
            modelType: ServerResponseModel<CreateOrUpdateProjectModel>.self
        )
        isEntityWasCreated = response.status?.value ?? false
        LoadingIndicator.stopLoading()
    }
}

extension CreatingProjectViewModel: UpdatableEntityProtocol {
    func updateValue<T>(for field: FieldType, value: T) {
        guard let value = value as? String else { return }
        switch field {
        case .title:
            creatingProject.title = value
        case .description:
            creatingProject.description = value
        case .code:
            creatingProject.code = value
        default: break
        }
    }
}
