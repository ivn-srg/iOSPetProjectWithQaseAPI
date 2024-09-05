//
//  DetailTabbarControllerViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 02.02.2024.
//

import Foundation
import UIKit

class DetailTabbarControllerViewModel {
    
    weak var delegate: UpdateDataInVCProtocol?
    var testCase: TestEntity? = nil {
        didSet {
            delegate?.updateUI()
        }
    }
    var caseId: Int
    
    init(caseId: Int) {
        self.caseId = caseId
    }
    
    // MARK: - Network work
    
    func fetchCaseDataJSON() {
        guard let urlString = Constants.urlString(.openedCase, Constants.PROJECT_NAME, nil, nil, nil, caseId) else { return }
        
        DispatchQueue.main.async {
            LoadingIndicator.startLoading()
        }
        
        APIManager.shared.fetchData(from: urlString, method: Constants.APIType.get.rawValue, token: Constants.TOKEN, modelType: TestCaseModel.self) { [weak self] (result: Result<TestCaseModel, Error>) in
            
            switch result {
            case .success(let jsonTestCase):
                self?.testCase = jsonTestCase.result
                
            case .failure(let error):
                print(error)
                DispatchQueue.main.async {
                    LoadingIndicator.stopLoading()
                }
            }
        }
    }
}
