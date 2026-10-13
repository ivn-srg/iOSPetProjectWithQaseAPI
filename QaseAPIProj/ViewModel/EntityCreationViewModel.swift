//
//  EntityCreationViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 21.09.2024.
//

import Foundation

@MainActor
final class EntityCreationViewModel {
    // MARK: - Fields
    weak var delegate: CheckEnablingRBBProtocol?
    var creatingEntityIsSuite = true { didSet { notifyChanges() } }
    var creatingTestCase: TestCaseEntity { didSet { delegate?.checkConditionAndToggleRightBarButton() } }
    var creatingSuite: TestListEntity { didSet { delegate?.checkConditionAndToggleRightBarButton() } }
    var isFieldsEmpty = false {
        didSet {
            if isFieldsEmpty {
                showErrorClosure(
                    "Not enough".localized,
                    "Probably you didn't fill all fields, check it, please".localized
                )
            }
        }
    }

    var isEntityWasCreated = false { didSet { if isEntityWasCreated { creatingFinishCallback() } } }
    private(set) var isSaving = false { didSet { notifyChanges() } }
    var creatingFinishCallback: () -> Void = {}
    var showErrorClosure: (String, String) -> Void = { (_, _) in }

    let projectCode: String
    private let network: NetworkManager
    private let session: SessionContext
    private let stamp: SessionStamp
    private var baselineCase: TestCaseEntity
    private var baselineSuite: TestListEntity
    let parentSuiteId: Int?
    var isSessionCurrent: Bool { session.isCurrent(stamp) }
    var suiteHasUnsavedChanges: Bool {
        creatingSuite.title != baselineSuite.title || creatingSuite.itemDescription != baselineSuite
            .itemDescription ||
            creatingSuite.preconditions != baselineSuite.preconditions || creatingSuite
            .parentId != baselineSuite.parentId
    }

    var caseHasUnsavedChanges: Bool { creatingTestCase != baselineCase }
    var hasUnsavedChanges: Bool { creatingEntityIsSuite ? suiteHasUnsavedChanges : caseHasUnsavedChanges }
    var hasAnyUnsavedChanges: Bool { suiteHasUnsavedChanges || caseHasUnsavedChanges }
    var canSaveDraft: Bool { validTitle(creatingEntityIsSuite ? creatingSuite.title : creatingTestCase.title)
    }

    var canSaveAllDrafts: Bool {
        isSessionCurrent && !isSaving && hasAnyUnsavedChanges &&
            (!suiteHasUnsavedChanges || validTitle(creatingSuite.title)) &&
            (!caseHasUnsavedChanges || validTitle(creatingTestCase.title))
    }

    var canCreate: Bool { canSaveDraft && hasUnsavedChanges && !isSaving && isSessionCurrent }

    func discardDraft() {
        guard !isSaving, isSessionCurrent else { return }
        creatingSuite = baselineSuite
        creatingTestCase = baselineCase
    }

    func selectParent(_ id: Int?, forSuite: Bool) {
        guard !isSaving, isSessionCurrent else { return }
        let value = id == 0 ? nil : id
        if forSuite { creatingSuite.parentId = value }
        else { creatingTestCase.suiteId = value }
    }

    private func validTitle(_ title: String) -> Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func notifyChanges() { delegate?.checkConditionAndToggleRightBarButton() }

    // MARK: - LifeCycle
    init(projectCode: String, parentSuiteId: Int? = nil, network: NetworkManager, session: SessionContext) {
        self.projectCode = projectCode
        self.network = network
        self.session = session
        self.stamp = session
            .capture()
        var initialCase = TestCaseEntity.empty
        initialCase.suiteId = parentSuiteId == 0 ? nil : parentSuiteId
        var initialSuite = TestListEntity.empty
        initialSuite
            .parentId = parentSuiteId == 0 ? nil : parentSuiteId
        self.baselineCase = initialCase
        self.baselineSuite = initialSuite
        self.parentSuiteId = parentSuiteId == 0 ? nil : parentSuiteId

        creatingSuite = TestListEntity.empty
        creatingTestCase = TestCaseEntity.empty

        creatingSuite.parentId = self.parentSuiteId
        creatingTestCase.suiteId = self.parentSuiteId
    }

    // MARK: - Network work
    func createNewEntity() async throws(API.NetError) {
        guard !isSaving else { throw .invalidRequest("A save is already in progress") }
        isEntityWasCreated = false
        guard isSessionCurrent,
              !Task.isCancelled else { throw .invalidRequest("The session is no longer active") }
        guard canSaveDraft else {
            isFieldsEmpty = true
            throw .invalidRequest("The draft cannot be saved")
        }
        guard hasUnsavedChanges else { throw .invalidRequest("The draft is already saved") }
        let forSuite = creatingEntityIsSuite
        let suiteDraft = creatingSuite
        let caseDraft = creatingTestCase
        guard let url = network.composeURL(
            for: forSuite ? .suites : .cases,
            urlComponents: [projectCode],
            queryItems: nil
        ) else { throw .invalidURL }
        isFieldsEmpty = false
        isSaving = true
        defer {
            isSaving = false
        }
        if forSuite {
            let response = try await network.performRequest(
                with: QaseAPISuiteCreateRequest(
                    title: suiteDraft.title,
                    description: suiteDraft.itemDescription,
                    preconditions: suiteDraft.preconditions,
                    parentId: suiteDraft.parentId
                ),
                from: url, method: .post, modelType: ServerResponseModel<CreateOrUpdateSuiteModel>.self
            )
            guard isSessionCurrent,
                  !Task.isCancelled else { throw .invalidRequest("The session is no longer active") }
            guard response.status?.value == true
            else { throw .invalidRequest("The entity could not be created") }
            baselineSuite = suiteDraft
        } else {
            let response = try await network.performRequest(
                with: caseDraft.dictOfValues,
                from: url,
                method: .post,
                modelType: ServerResponseModel<CreateOrUpdateTestCaseModel>.self
            )
            guard isSessionCurrent,
                  !Task.isCancelled else { throw .invalidRequest("The session is no longer active") }
            guard response.status?.value == true
            else { throw .invalidRequest("The entity could not be created") }
            baselineCase = caseDraft
        }
        isSaving = false
        isEntityWasCreated = true
    }

}

extension EntityCreationViewModel: UpdatableEntityProtocol {
    var formCase: TestCaseEntity? { creatingTestCase }
    var formParentID: Int? { parentSuiteId }

    func updateValue(for field: FieldType, value: FormFieldValue) {
        guard !isSaving, isSessionCurrent else { return }
        if creatingEntityIsSuite {
            updateSuite(for: field, value: value)
        } else {
            updateTestCase(for: field, value: value)
        }
    }

    private func updateSuite(for field: FieldType, value: FormFieldValue) {
        guard let value = value.text else {
            guard field == .parentSuite, let value = value.selectionID else { return }
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

    private func updateTestCase(for field: FieldType, value: FormFieldValue) {
        switch field {
        case .title, .description, .precondition, .postcondition:
            guard let value = value.text else { return }

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
            if field == .isFlaky {
                if let value = value.toggle { creatingTestCase.isFlaky = value }
                return
            }
            guard let id = value.selectionID else { return }

            switch field {
            case .severity:
                creatingTestCase.severity = Severity(id)
            case .status:
                creatingTestCase.status = Status(id)
            case .priority:
                creatingTestCase.priority = Priority(id)
            case .behavior:
                creatingTestCase.behavior = Behavior(id)
            case .type:
                creatingTestCase.type = Types(id)
            case .layer:
                creatingTestCase.layer = Layer(id)
            case .automation:
                creatingTestCase.automation = AutomationStatus(id)
            default: break
            }
        case .parentSuite:
            if let id = value.selectionID { selectParent(id, forSuite: false) }
        default: break
        }
    }
}
