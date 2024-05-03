//
//  DetailTabbarControllerViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 02.02.2024.
//

import Foundation
import UIKit

class DetailTabbarControllerViewModel {
    
    var dataSource: TestCaseModel?
    var testCase: TestEntity? = nil
    var caseId = 0
    
    init(caseId: Int) {
        self.caseId = caseId
    }
    
    // MARK: - Network work
    
    func updateDataSource() {
        
        func fetchProjectsJSON(_ token: String, limit: Int? = nil, Offset: Int? = nil, caseId: Int?) {
            guard let urlString = Constants.urlString(.openedCase, Constants.PROJECT_NAME, nil, nil, nil, caseId) else { return }
            
            APIManager.shared.fetchData(from: urlString, method: Constants.APIType.get.rawValue, token: token, modelType: TestCaseModel.self) { [weak self] (result: Result<TestCaseModel, Error>) in
                
                
                switch result {
                case .success(let jsonTestCase):
                    self?.dataSource = jsonTestCase
                    self?.mapTestCaseData()
                    
                case .failure(let error):
                    if let apiError = error as? APIError, apiError == .invalidURL {
                        DispatchQueue.main.async {
                            LoadingIndicator.stopLoading()
                        }
                    } else {
                        DispatchQueue.main.async {
                            LoadingIndicator.stopLoading()
                        }
                    }
                }
            }
        }
        
        fetchProjectsJSON(Constants.TOKEN, caseId: self.caseId)
    }
    
    private func mapTestCaseData() {
        testCase = self.dataSource?.result
    }
    
    // MARK: - Routing
    
    func navigateTo(_ row: Int) {
        
    }
    
    // MARK: - VC func
}
