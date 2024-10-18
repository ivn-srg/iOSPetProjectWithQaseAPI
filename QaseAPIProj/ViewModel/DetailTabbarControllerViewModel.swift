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
            DispatchQueue.main.async {
                self.delegate?.updateUI()
            }
        }
    }
    var changedTestCase: TestEntity? {
        didSet {
            DispatchQueue.main.async {
                self.checkDataChanged()
            }
        }
    }
    var isUploadingSuccess = false {
        didSet {
            DispatchQueue.main.async {
                self.updatingFinishCallback()
            }
        }
    }
    var caseId: Int
    var updatingFinishCallback: () -> Void = {}
    var checkDataChanged: () -> Void = {}
    
    // MARK: - Lifecycle
    init(caseId: Int) {
        self.caseId = caseId
    }
    
    // MARK: - Network work
    func fetchCaseDataJSON() {
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
            fetchCaseDataJSON()
            LoadingIndicator.stopLoading()
        }
    }
    
    // MARK: - objc funcs
    @objc func saveChangedData() {}
}
