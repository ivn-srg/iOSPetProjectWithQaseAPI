//
//  CreateSuiteOrCaseVIewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 21.09.2024.
//

import Foundation

final class CreateSuiteOrCaseViewModel {
    // MARK: - Fields
    weak var delegate: CheckEnablingRBBProtocol?
    var creatingEntityIsSuite = true
    var creatingTestCase: CreatingTestCase {
        didSet {
            Task { @MainActor in
                delegate?.checkConditionAndToggleRightBarButton()
            }
        }
    }
    var creatingSuite: CreatingSuite {
        didSet {
            Task { @MainActor in
                delegate?.checkConditionAndToggleRightBarButton()
            }
        }
    }
    var isFieldsEmpty = false {
        didSet {
            if isFieldsEmpty {
                Task { @MainActor in emptyFieldsClosure() }
            }
        }
    }
    var isEntityWasCreated = false {
        didSet {
            if isEntityWasCreated {
                Task { @MainActor in creatingFinishCallback() }
            }
        }
    }
    var creatingFinishCallback: () -> Void = {}
    var emptyFieldsClosure: () -> Void = {}
    
    let parentSuiteId: Int
    
    // MARK: - LifeCycle
    init(parentSuiteId: Int? = 0) {
        if let parentSuiteId = parentSuiteId {
            self.parentSuiteId = parentSuiteId
        } else { self.parentSuiteId = 0 }
        creatingSuite = CreatingSuite.empty
        creatingTestCase = CreatingTestCase.empty
    }
    
    // MARK: - Network work
    func createNewEntity() async throws(APIError) {
        isFieldsEmpty = creatingEntityIsSuite ? creatingSuite.title.isEmpty : creatingTestCase.title.isEmpty
        if isFieldsEmpty { return }
            
        guard let urlString = apiManager.formUrlString(
            APIMethod: creatingEntityIsSuite ? .suites : .cases,
            codeOfProject: PROJECT_NAME
        ) else { throw .invalidURL }
        
        LoadingIndicator.startLoading()
        
        if creatingEntityIsSuite {
            let response = try await apiManager.performRequest(
                with: creatingSuite,
                from: urlString,
                method: .post,
                modelType: ServerResponseModel<CreateOrUpdateSuiteModel>.self
            )
            isEntityWasCreated = response.status.value
        } else {
            let response = try await apiManager.performRequest(
                with: creatingTestCase,
                from: urlString,
                method: .post,
                modelType: ServerResponseModel<CreateOrUpdateTestCaseModel>.self
            )
            isEntityWasCreated = response.status.value
        }
        LoadingIndicator.stopLoading()
    }
}
