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
                self.delegate?.checkConditionAndToggleRightBarButton()
            }
        }
    }
    var isTestCaseDataEditing = false
    var caseId: Int
    
    // MARK: - Lifecycle
    init(caseId: Int) {
        self.caseId = caseId
    }
    
    // MARK: - Network work
    func fetchCaseDataJSON() {
        guard let urlString = Constants.urlString(.openedCase, Constants.PROJECT_NAME, nil, nil, nil, caseId) else { return }
        
        LoadingIndicator.startLoading()
        
        APIManager.shared.fetchData(
            from: urlString,
            method: Constants.APIType.get.rawValue,
            token: Constants.TOKEN,
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
    
    func updateTestCaseData() {}
    
    // MARK: - objc funcs
    @objc func saveChangedData() {
        if isTestCaseDataEditing {
            // TODO: - Make a network request for update test case info
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3, execute: DispatchWorkItem(block: {
                print("Test case data has been saved")
            }))
            isTestCaseDataEditing = false
        }
    }
}
