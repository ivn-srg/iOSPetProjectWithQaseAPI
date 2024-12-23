//
//  DetailTabbarControllerViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 02.02.2024.
//

import Foundation
import UIKit

final class DetailTabbarControllerViewModel {
    // MARK: - fields
    weak var delegate: DetailTestCaseProtocol?
    var testCase: TestEntity? = nil {
        didSet {
            Task { @MainActor in
                delegate?.updateUI()
            }
        }
    }
    var changedTestCase: TestEntity? {
        didSet {
            Task { @MainActor in
                checkDataChanged()
            }
        }
    }
    var isUploadingSuccess = false {
        didSet {
            Task { @MainActor in
                updatingFinishCallback()
            }
        }
    }
    var caseId: Int
    var updatingFinishCallback: () -> Void = {}
    var checkDataChanged: () -> Void = {}
    private let realmDb = RealmManager.shared
    
    // MARK: - Lifecycle
    init(caseId: Int) {
        self.caseId = caseId
    }
    
    // MARK: - Network work
    func fetchCaseDataJSON() async throws {
        if let cashedTestCase = realmDb.getTestCase(by: caseId) {
            testCase = cashedTestCase
            changedTestCase = testCase
            
            LoadingIndicator.stopLoading()
            return
        }
        
        guard let urlString = apiManager.formUrlString(
                                            APIMethod: .openedCase,
                                            codeOfProject: PROJECT_NAME,
                                            limit: nil,
                                            offset: nil,
                                            parentSuite: nil,
                                            caseId: caseId
                                        ) else { return }
        LoadingIndicator.startLoading()
        
        let testCaseResult = try await apiManager.performRequest(
            from: urlString,
            method: .get,
            modelType: TestCaseModel.self)
        
        let _ = realmDb.saveTestCase(testCaseResult.result)
        testCase = testCaseResult.result
        changedTestCase = testCase
        
        LoadingIndicator.stopLoading()
        
    }
    
    func updateTestCaseData() async throws {
        guard let changedTestCase = changedTestCase else { return }
        guard let urlString = apiManager.formUrlString(
                                            APIMethod: .openedCase,
                                            codeOfProject: PROJECT_NAME,
                                            limit: nil,
                                            offset: nil,
                                            parentSuite: nil,
                                            caseId: testCase?.id
                                        ) else { return }
        LoadingIndicator.startLoading()
        
        let response = try await apiManager.performRequest(
            with: changedTestCase.dictOfValues,
            from: urlString,
            method: .patch,
            modelType: ServerResponseModel<CreateOrUpdateTestCaseModel>.self
        )
        
        isUploadingSuccess = response.status?.value ?? false
        let _ = isUploadingSuccess ? realmDb.saveTestCase(changedTestCase) : nil
        try await fetchCaseDataJSON()
        LoadingIndicator.stopLoading()
    }
}

extension DetailTabbarControllerViewModel: UpdatableEntityProtocol {
    func updateValue<T>(for field: FieldType, value: T) {
        switch field {
        case .title, .description, .precondition, .postcondition:
            guard let value = value as? String else { return }
            
            switch field {
            case .title:
                changedTestCase?.title = value
            case .description:
                changedTestCase?.description = value
            case .precondition:
                changedTestCase?.preconditions = value
            case .postcondition:
                changedTestCase?.postconditions = value
            default: break
            }
        case .severity, .status, .priority, .behavior, .type, .layer, .isFlaky, .automation:
            switch field {
            case .severity:
                changedTestCase?.severity = value as? Severity ?? Severity.nothing
            case .status:
                changedTestCase?.status = value as? Status ?? Status.actual
            case .priority:
                changedTestCase?.priority = value as? Priority ?? Priority.nothing
            case .behavior:
                changedTestCase?.behavior = value as? Behavior ?? Behavior.nothing
            case .type:
                changedTestCase?.type = value as? Types ?? Types.other
            case .layer:
                changedTestCase?.layer = value as? Layer ?? Layer.e2e
            case .isFlaky:
                changedTestCase?.isFlaky = value as? Int ?? 0
            case .automation:
                changedTestCase?.automation = value as? AutomationStatus ?? AutomationStatus.manual
            default: break
            }
        default: break
        }
    }
}
