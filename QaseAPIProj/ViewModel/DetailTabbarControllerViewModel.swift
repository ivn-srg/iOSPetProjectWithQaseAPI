//
//  DetailTabbarControllerViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 02.02.2024.
//

import Foundation
import UIKit

class DetailTabbarControllerViewModel {
    
    var isLoadingData: Observable<Bool> = Observable(false)
    var dataSource: TestCaseModel?
    
    // MARK: - Network work
    
    func updateDataSource() {
        if isLoadingData.value ?? true {
            return
        }
        let limit = 100
        var offset = 0
        var totalCount = 0
        
        func fetchProjectsJSON(_ token: String, limit: Int?, Offset: Int?, caseId: Int?) {
            guard let urlString = Constants.urlString(.openedCase, nil, nil, nil, caseId) else { return }
            
            isLoadingData.value = true
            APIManager.shared.fetchData(from: urlString, method: Constants.APIType.get.rawValue, token: token, modelType: TestCaseModel.self) { [weak self] (result: Result<TestCaseModel, Error>) in
                self?.isLoadingData.value = false
                
                switch result {
                case .success(let jsonTestCase):
                    self?.dataSource = jsonTestCase
                    self?.mapTestCaseData()
                    
                    
//                    DispatchQueue.main.async {
//                        LoadingIndicator.stopLoading()
//                    }
                case .failure(let error):
                    if let apiError = error as? APIError, apiError == .invalidURL {
                        DispatchQueue.main.async {
                            LoadingIndicator.stopLoading()
                            //                            self?.showErrorAlert(titleAlert: "Error", messageAlert: "Invalid URL")
                        }
                    } else {
                        DispatchQueue.main.async {
                            LoadingIndicator.stopLoading()
//                                                        self?.showErrorAlert(titleAlert: "Something went wrong", messageAlert: "\(error)")
                        }
                    }
                }
            }
        }
        
        fetchProjectsJSON(Constants.TOKEN, limit: limit, Offset: offset, caseId: nil)
    }
    
    private func mapTestCaseData() {
        da.value = self.dataSource?.result
    }
    
    // MARK: - Routing
    
    func navigateTo(_ row: Int) {
        
    }
    
    // MARK: - VC func
    
    func numberOfRows() -> Int {
        dataSource?.result.entities.count ?? 0
    }
}
