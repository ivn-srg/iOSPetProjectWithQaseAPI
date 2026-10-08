//
//  CreateSuiteOrCaseVIewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 21.09.2024.
//

import Foundation

@MainActor
final class CreateSuiteOrCaseViewModel {
    // MARK: - Fields
    weak var delegate: CheckEnablingRBBProtocol?
    var creatingEntityIsSuite = true
    var creatingTestCase: TestCaseEntity { didSet { delegate?.checkConditionAndToggleRightBarButton() } }
    var creatingSuite: TestListEntity { didSet { delegate?.checkConditionAndToggleRightBarButton() } }
    var isFieldsEmpty = false {
        didSet {
            if isFieldsEmpty {
                showErrorClosure("Not enough".localized, "Probably you didn't fill all fields, check it, please".localized)
            }
        }
    }
    var isEntityWasCreated = false {
        didSet {
            if isEntityWasCreated { creatingFinishCallback() }
            else { showErrorClosure("Error".localized, "Something went wrong".localized) }
        }
    }
    var creatingFinishCallback: () -> Void = {}
    var showErrorClosure: (String, String) -> Void = { (_,_) in }
    
    let projectCode: String
    private let network: NetworkManager
    private let session: SessionContext
    private let stamp: SessionStamp
    private var baselineCase: TestCaseEntity
    private var baselineSuite: TestListEntity
    let parentSuiteId: Int?
    var hasUnsavedChanges: Bool {
        if creatingEntityIsSuite {
            return creatingSuite.title != baselineSuite.title || creatingSuite.itemDescription != baselineSuite.itemDescription || creatingSuite.preconditions != baselineSuite.preconditions || creatingSuite.parentId != baselineSuite.parentId
        }
        return creatingTestCase != baselineCase
    }
    var canSaveDraft: Bool { !(creatingEntityIsSuite ? creatingSuite.title : creatingTestCase.title).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    func discardDraft() { creatingSuite = baselineSuite; creatingTestCase = baselineCase }
    
    // MARK: - LifeCycle
    init(projectCode: String, parentSuiteId: Int? = nil, network: NetworkManager = ApiServiceConfiguration.shared.apiService, session: SessionContext? = nil) {
        let session = session ?? .shared
        self.projectCode = projectCode; self.network = network; self.session = session; self.stamp = session.capture()
        var initialCase = TestCaseEntity.empty; initialCase.suiteId = parentSuiteId
        var initialSuite = TestListEntity.empty; initialSuite.parentId = parentSuiteId
        self.baselineCase = initialCase; self.baselineSuite = initialSuite
        self.parentSuiteId = parentSuiteId
        
        creatingSuite = TestListEntity.empty
        creatingTestCase = TestCaseEntity.empty
        
        creatingSuite.parentId = self.parentSuiteId
        creatingTestCase.suiteId = self.parentSuiteId
    }
    
    // MARK: - Network work
    func createNewEntity() async throws(API.NetError) {
        guard session.isCurrent(stamp) else { return }
        isFieldsEmpty = !canSaveDraft
        if isFieldsEmpty { return }
        
        guard
            let urlString = network.composeURL(for: creatingEntityIsSuite ? .suites : .cases, urlComponents: [projectCode], queryItems: nil)
        else { throw .invalidURL }
        
        LoadingIndicator.startLoading()
        defer { if session.isCurrent(stamp) { LoadingIndicator.stopLoading() } }
        
        if creatingEntityIsSuite {
            let draft = creatingSuite
            let response = try await network.performRequest(
                with: QaseAPISuiteCreateRequest(title: draft.title, description: draft.itemDescription, preconditions: draft.preconditions, parentId: draft.parentId),
                from: urlString,
                method: .post,
                modelType: ServerResponseModel<CreateOrUpdateSuiteModel>.self
            )
            guard session.isCurrent(stamp) else { return }
            guard response.status?.value == true else { throw .invalidRequest("The entity could not be created") }
            baselineSuite = draft
            isEntityWasCreated = true
        } else {
            let draft = creatingTestCase
            let response = try await network.performRequest(
                with: draft.dictOfValues,
                from: urlString,
                method: .post,
                modelType: ServerResponseModel<CreateOrUpdateTestCaseModel>.self
            )
            guard session.isCurrent(stamp) else { return }
            guard response.status?.value == true else { throw .invalidRequest("The entity could not be created") }
            baselineCase = draft
            isEntityWasCreated = true
        }
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
            creatingSuite.parentId = value == 0 ? nil : value
            return
        }
        
        switch field {
        case .title:
            creatingSuite.title = value
        case .description:
            creatingSuite.itemDescription = value
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
                guard field == .isFlaky, let value = value as? Bool else { return }
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
