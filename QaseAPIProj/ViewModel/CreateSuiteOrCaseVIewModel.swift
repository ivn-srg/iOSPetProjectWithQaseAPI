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
    var creatingEntityIsSuite: Bool = true
    var creatingTestCase: CreatingTestCase {
        didSet {
            Task { @MainActor in
                self.delegate?.checkConditionAndToggleRightBarButton()
            }
        }
    }
    var creatingSuite: CreatingSuite {
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
        self.creatingSuite = CreatingSuite.empty
        self.creatingTestCase = CreatingTestCase.empty
    }
    
    // MARK: - Network work
    func createNewEntity() {
        isFieldsEmpty = creatingEntityIsSuite ? creatingSuite.title.isEmpty : creatingTestCase.title.isEmpty
        if isFieldsEmpty { return }
            
        guard let urlString = apiManager.formUrlString(
            APIMethod: creatingEntityIsSuite ? .suites : .cases,
            codeOfProject: PROJECT_NAME,
            limit: nil,
            offset: nil,
            parentSuite: nil,
            caseId: nil
        ) else { return }
        LoadingIndicator.startLoading()
        
        Task {
            if creatingEntityIsSuite {
                let response = try await apiManager.performRequest(
                    with: creatingSuite,
                    from: urlString,
                    method: .post,
                    modelType: ServerResponseModel<CreateOrUpdateSuiteModel>.self
                )
                isEntityWasCreated = response.status
            } else {
                let response = try await apiManager.performRequest(
                    with: creatingTestCase,
                    from: urlString,
                    method: .post,
                    modelType: ServerResponseModel<CreateOrUpdateTestCaseModel>.self
                )
                isEntityWasCreated = response.status
            }
            LoadingIndicator.stopLoading()
        }
    }
}
