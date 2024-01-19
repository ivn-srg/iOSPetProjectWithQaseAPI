//
//  SuitesAndCasesTableViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 19.01.2024.
//

import Foundation

class SuitesAndCasesViewModel {
    
    var isLoadingData: Observable<Bool> = Observable(false)
    var codeOfProject = ""
    var parentSuite: Int? = nil
    var suiteDataSource: SuitesDataModel?
    var caseDataSource: TestCasesModel?
    var suitesAndCaseData = [SuiteAndCaseData]()
    
    var filteredData = [SuiteAndCaseData]()
    
    var suitesAndCases: Observable<[SuitesAndCasesTableViewCellViewModel]> = Observable(nil)
    
    // MARK: - Network work
    
    func updateDataSource() {
        if isLoadingData.value ?? true {
            return
        }
        let limit = 100
        var offset = 0
        var totalCount = 0
        var parsedSuites: [SuiteEntity] = []
        var parsedCases: [TestEntity] = []
        
        func fetchSuitesJSON(_ token: String, projectCode: String, limit: Int) {
            let urlString = Constants.urlString(Constants.APIMethods.suite.rawValue, projectCode, limit, offset)
            
            isLoadingData.value = true
            APIManager.shared.fetchData(from: urlString, method: Constants.APIType.get.rawValue, token: token, modelType: SuitesDataModel.self) { [weak self] (result: Result<SuitesDataModel, Error>) in
                
                switch result {
                case .success(let jsonSuites):
                    if totalCount == 0 {
                        totalCount = jsonSuites.result.total
                    }
                    parsedSuites += jsonSuites.result.entities
                    
                    offset = parsedSuites.count
                    
                case .failure(let error):
                    if let apiError = error as? APIError, apiError == .invalidURL {
                        DispatchQueue.main.async {
                            LoadingIndicator.stopLoading()
//                            showErrorAlert(titleAlert: "Error", messageAlert: "Invalid URL")
                        }
                    } else {
                        DispatchQueue.main.async {
                            LoadingIndicator.stopLoading()
//                            showErrorAlert(titleAlert: "Something went wrong", messageAlert: "\(error)")
                        }
                    }
                }
            }
        }
        
        func fetchCasesJSON(_ token: String, projectCode: String, limit: Int) {
            let urlString = Constants.urlString(Constants.APIMethods.cases.rawValue, projectCode, limit, offset)
            
            APIManager.shared.fetchData(from: urlString, method: Constants.APIType.get.rawValue, token: token, modelType: TestCasesModel.self) { [weak self] (result: Result<TestCasesModel, Error>) in
                
                switch result {
                case .success(let jsonCases):
                    
                    if totalCount == 0 {
                        totalCount = jsonCases.result.total
                    }
                    parsedCases += jsonCases.result.entities
                    
                    offset = parsedCases.count
                    
                case .failure(let error):
                    if let apiError = error as? APIError, apiError == .invalidURL {
                        DispatchQueue.main.async {
                            LoadingIndicator.stopLoading()
//                            self?.showErrorAlert(titleAlert: "Error", messageAlert: "Invalid URL")
                        }
                    } else {
                        DispatchQueue.main.async {
                            LoadingIndicator.stopLoading()
//                            self?.showErrorAlert(titleAlert: "Something went wrong", messageAlert: "\(error)")
                        }
                    }
                }
            }
        }
        
        if suitesAndCaseData.isEmpty {
            repeat {
                fetchSuitesJSON(Constants.TOKEN, projectCode: self.codeOfProject, limit: limit)
            } while totalCount > offset
            
            self.changeDataTypeToUniversalizeData(isSuite: true, targetUniversalList: &self.suitesAndCaseData, suites: parsedSuites, testCases: nil)
            totalCount = 0
            offset = 0
            parsedSuites.removeAll()
            
            repeat {
                fetchCasesJSON(Constants.TOKEN, projectCode: self.codeOfProject, limit: limit)
            } while totalCount > offset
            
            
            self.changeDataTypeToUniversalizeData(isSuite: false, targetUniversalList: &self.suitesAndCaseData, suites: nil, testCases: parsedCases)
        }
        mapSuitesAndCasesData()
        isLoadingData.value = false
    }
    
    private func mapSuitesAndCasesData() {
        if parentSuite == nil {
            filteredData = suitesAndCaseData.filter( {$0.parent_id == nil && $0.suiteId == nil} )
            
        } else {
            filteredData = suitesAndCaseData.filter( {$0.parent_id == self.parentSuite || $0.suiteId == self.parentSuite} )
        }
        suitesAndCases.value = self.filteredData.compactMap({SuitesAndCasesTableViewCellViewModel(suiteOrCase: $0)})
    }
    
    private func changeDataTypeToUniversalizeData(
        isSuite: Bool,
        targetUniversalList: inout [SuiteAndCaseData],
        suites: [SuiteEntity]?,
        testCases: [TestEntity]?
    ) {
        if isSuite {
            guard let suites = suites else { return }
            
            for suite in suites {
                let universalItem = SuiteAndCaseData(
                    isSuite: true,
                    id: suite.id,
                    title: suite.title,
                    description: suite.description,
                    preconditions: suite.preconditions,
                    parent_id: suite.parent_id,
                    case_count: suite.cases_count
                )
                
                targetUniversalList.append(universalItem)
            }
        } else {
            guard let testCases = testCases else { return }
            
            for testCase in testCases {
                let universalItem = SuiteAndCaseData(
                    isSuite: false,
                    id: testCase.id,
                    title: testCase.title,
                    description: testCase.description,
                    preconditions: testCase.preconditions,
                    parent_id: nil,
                    case_count: nil,
                    priority: testCase.priority,
                    automation: testCase.automation,
                    suiteId: testCase.suiteId
                )
                
                targetUniversalList.append(universalItem)
            }
        }
    }
    
    // MARK: - Routing
    
    func navigateTo(_ row: Int) {
       
    }
    
    // MARK: - VC func
    
    func numberOfRows() -> Int {
        filteredData.count
    }
    
    func getSuiteTitle() -> String? {
        return parentSuite == nil ? codeOfProject : self.suitesAndCaseData.filter( {$0.isSuites && $0.id == self.parentSuite} ).first?.title
    }
}
