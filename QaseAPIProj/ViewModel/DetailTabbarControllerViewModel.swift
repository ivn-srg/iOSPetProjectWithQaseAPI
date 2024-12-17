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
                self.delegate?.updateUI()
            }
        }
    }
    var changedTestCase: TestEntity? {
        didSet {
            Task { @MainActor in
                self.checkDataChanged()
            }
        }
    }
    var isUploadingSuccess = false {
        didSet {
            Task { @MainActor in
                self.updatingFinishCallback()
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
    func fetchCaseDataJSON() {
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
        
        Task {
            let testCaseResult = try await apiManager.performRequest(
                from: urlString,
                method: .get,
                modelType: TestCaseModel.self)
            
            let _ = realmDb.saveTestCase(testCaseResult.result)
            testCase = testCaseResult.result
            changedTestCase = testCase
            
            LoadingIndicator.stopLoading()
        }
    }
    
    func updateTestCaseData() {
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
        
        Task {
            let response = try await apiManager.performRequest(
                with: changedTestCase,
                from: urlString,
                method: .patch,
                modelType: ServerResponseModel<CreateOrUpdateTestCaseModel>.self
            )
            
            isUploadingSuccess = response.status
            let _ = realmDb.saveTestCase(changedTestCase)
            fetchCaseDataJSON()
            LoadingIndicator.stopLoading()
        }
    }
}
