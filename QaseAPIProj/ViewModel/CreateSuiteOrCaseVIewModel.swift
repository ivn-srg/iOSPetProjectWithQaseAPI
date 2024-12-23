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
    var creatingTestCase: TestEntity {
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
        creatingTestCase = TestEntity.empty
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
            isEntityWasCreated = response.status?.value ?? false
        } else {
            let response = try await apiManager.performRequest(
                with: creatingTestCase.dictOfValues,
                from: urlString,
                method: .post,
                modelType: ServerResponseModel<CreateOrUpdateTestCaseModel>.self
            )
            isEntityWasCreated = response.status?.value ?? false
        }
        LoadingIndicator.stopLoading()
    }
}

extension CreateSuiteOrCaseViewModel: UpdatableEntityProtocol {
    func updateValue<T>(for field: FieldType, value: T) {
        if creatingEntityIsSuite {
            updateSuite(for: field, value: value)
        } else {
            updateTestCase(for: field, value: value)
        }
    }
    
    private func updateSuite<T>(for field: FieldType, value: T) {
        guard let value = value as? String else {
            guard field == .parentSuite, let value = value as? Int else { return }
            creatingSuite.parentId = value
            return
        }
        
        switch field {
        case .title:
            creatingSuite.title = value
        case .description:
            creatingSuite.description = value
        case .precondition:
            creatingSuite.preconditions = value
        default: break
        }
    }
    
    private func updateTestCase<T>(for field: FieldType, value: T) {
        switch field {
        case .title, .description, .precondition, .postcondition:
            guard let value = value as? String else { return }
            
            switch field {
            case .title:
                creatingTestCase.title = value
            case .description:
                creatingTestCase.description = value
            case .precondition:
                creatingTestCase.preconditions = value
            case .postcondition:
                creatingTestCase.postconditions = value
            default: break
            }
        case .severity, .status, .priority, .behavior, .type, .layer, .isFlaky, .automation:
            guard let value = value as? MenuItem else {
                guard field == .isFlaky, let value = value as? Int else { return }
                creatingTestCase.isFlaky = value
                return
            }
            
            switch field {
            case .severity:
                creatingTestCase.severity = Severity(value.id)
            case .status:
                creatingTestCase.status = Status(value.id)
            case .priority:
                creatingTestCase.priority = Priority(value.id)
            case .behavior:
                creatingTestCase.behavior = Behavior(value.id)
            case .type:
                creatingTestCase.type = Types(value.id)
            case .layer:
                creatingTestCase.layer = Layer(value.id)
            case .automation:
                creatingTestCase.automation = AutomationStatus(value.id)
            default: break
            }
        default: break
        }
    }
}
