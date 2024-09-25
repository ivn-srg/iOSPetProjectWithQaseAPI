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
        guard let urlString = Constants.getUrlString(
                                            APIMethod: .openedCase,
                                            codeOfProject: Constants.PROJECT_NAME,
                                            limit: nil,
                                            offset: nil,
                                            parentSuite: nil,
                                            caseId: caseId
                                        ) else { return }
        
        LoadingIndicator.startLoading()
        
        APIManager.shared.fetchData(
            from: urlString,
            method: Constants.APIType.get.rawValue,
            modelType: TestCaseModel.self
        ) { [weak self] (result: Result<TestCaseModel, Error>) in
            
            switch result {
            case .success(let jsonTestCase):
                self?.testCase = jsonTestCase.result
                self?.changedTestCase = self?.testCase
                
            case .failure(let error):
                print(error)
            }
            
            LoadingIndicator.stopLoading()
        }
    }
    
    func updateTestCaseData() {
        LoadingIndicator.startLoading()
        guard let changedTestCase = changedTestCase else { return }
        guard let urlString = Constants.getUrlString(
                                            APIMethod: .openedCase,
                                            codeOfProject: Constants.PROJECT_NAME,
                                            limit: nil,
                                            offset: nil,
                                            parentSuite: nil,
                                            caseId: testCase?.id
                                        ) else { return }
        APIManager.shared.updateTestCaseData(
            newData: changedTestCase,
            from: urlString,
            method: Constants.APIType.patch.rawValue,
            modelType: ServerResponseModel<CreateOrUpdateTestCaseModel>.self) {
                [weak self] (result: Result<ServerResponseModel<CreateOrUpdateTestCaseModel>, Error>) in
            
            switch result {
            case .success(let jsonUpdateResult):
                self?.isUploadingSuccess = jsonUpdateResult.status
                self?.fetchCaseDataJSON()
            case .failure(let error):
                print(error)
            }
            LoadingIndicator.stopLoading()
        }
    }
    
    // MARK: - objc funcs
    @objc func saveChangedData() {}
}
