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
    var testCase: TestCaseEntity? = nil {
        didSet {
            Task { @MainActor in delegate?.updateUI() }
        }
    }
    var changedTestCase: TestCaseEntity? {
        didSet {
            Task { @MainActor in checkDataChanged() }
        }
    }
    var isUploadingSuccess = false {
        didSet {
            if isUploadingSuccess {
                Task { @MainActor in updatingFinishCallback() }
            }
        }
    }
    var caseUniqueKey: String
    var caseId: Int {
        guard let caseSubstring = caseUniqueKey.split(separator: "_").first,
              let caseId = Int(caseSubstring)
        else { return 0 }
        return caseId
    }
    var updatingFinishCallback: () -> Void = {}
    var checkDataChanged: () -> Void = {}
    private let realmDb = RealmManager.shared
    
    // MARK: - Lifecycle
    init(caseUniqueKey: String) {
        self.caseUniqueKey = caseUniqueKey
    }
    
    // MARK: - Network work
    func fetchCaseDataJSON() async throws(API.NetError) {
        if let cashedTestCase = realmDb.getTestCase(by: caseUniqueKey) {
            testCase = cashedTestCase
            changedTestCase = testCase
            
            LoadingIndicator.stopLoading()
            return
        }
        
        guard
            let urlString = apiManager.composeURL(for: .cases, urlComponents: [PROJECT_NAME, String(caseId)], queryItems: nil)
        else { throw .invalidURL }
        
        LoadingIndicator.startLoading()
        
        let testCaseResult = try await apiManager.performRequest(
            with: nil, from: urlString,
            method: .get,
            modelType: TestCaseModel.self)
        
        let _ = realmDb.saveTestCase(testCaseResult.result)
        testCase = testCaseResult.result
        changedTestCase = testCase
        
        LoadingIndicator.stopLoading()
    }
    
    func updateTestCaseData() async throws(API.NetError) {
        guard let changedTestCase = changedTestCase else { return }
        
        guard
            let testCaseId = testCase?.id,
            let urlString = apiManager.composeURL(for: .cases, urlComponents: [PROJECT_NAME, String(testCaseId)], queryItems: nil)
        else { throw .invalidURL }
        
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
            
            let intValue = value as? Int
            
            switch field {
            case .severity:
                changedTestCase?.severity = Severity(intValue ?? 0)
            case .status:
                changedTestCase?.status = Status(intValue ?? 0)
            case .priority:
                changedTestCase?.priority = Priority(intValue ?? 0)
            case .behavior:
                changedTestCase?.behavior = Behavior(intValue ?? 0)
            case .type:
                changedTestCase?.type = Types(intValue ?? 0)
            case .layer:
                changedTestCase?.layer = Layer(intValue ?? 0)
            case .isFlaky:
                changedTestCase?.isFlaky = value as? Bool ?? false
            case .automation:
                changedTestCase?.automation = AutomationStatus(intValue ?? 0)
            default: break
            }
        default: break
        }
    }
}
