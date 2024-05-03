//
//  SuitesAndCasesViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 03.05.2024.
//

import Foundation


final class SuitesAndCasesViewModel {
    // MARK: - Fields
    var delegate: UpdateTableViewProtocol?
    var parentSuite: Int?
    private var totalCountOfSuites = 0
    private var totalCountOfCases = 0
    
    var suitesAndCaseData = [SuiteAndCaseData]() {
        didSet {
            if parentSuite == nil {
                suitesAndCaseData = suitesAndCaseData.filter( {$0.parent_id == nil && $0.suiteId == nil} )
            }
            delegate?.updateTableView()
        }
    }
    
    // MARK: - lifecycle
    
    init(delegate: UpdateTableViewProtocol? = nil, parentSuite: Int? = nil) {
        self.delegate = delegate
        self.parentSuite = parentSuite
    }
    
    // MARK: - Network funcs
    
    func requestEntitiesData() {
        getTotalCountOfEntities()
        fetchSuitesJSON()
        fetchCasesJSON()
    }
    
    private func getTotalCountOfEntities() {
        guard let urlStringSuites = Constants.urlString(.suitesWithoutParent, Constants.PROJECT_NAME, 1, 0, nil, nil) else { return }
        guard let urlStringCases = Constants.urlString(.casesWithoutParent, Constants.PROJECT_NAME, 1, 0, nil, nil) else { return }
        
        DispatchQueue.main.async {
            LoadingIndicator.startLoading()
        }
        
        APIManager.shared.fetchData(from: urlStringSuites, method: Constants.APIType.get.rawValue, token: Constants.TOKEN, modelType: SuitesDataModel.self) { [weak self] (result: Result<SuitesDataModel, Error>) in
            switch result {
            case .success(let jsonSuites):
                self?.totalCountOfSuites = jsonSuites.result.total
            case .failure(let error):
                print(error)
                break
            }
        }
        
        APIManager.shared.fetchData(from: urlStringCases, method: Constants.APIType.get.rawValue, token: Constants.TOKEN, modelType: TestCasesModel.self) { [weak self] (result: Result<TestCasesModel, Error>) in
            switch result {
            case .success(let jsonCases):
                self?.totalCountOfCases = jsonCases.result.total
            case .failure(let error):
                print(error)
                break
            }
        }
    }
    
    private func fetchSuitesJSON() {
        let limit = 100
        var offset = 0
        var urlStringSuites = ""
        
        repeat {
            if parentSuite != nil {
                urlStringSuites = Constants.urlString(.suites, Constants.PROJECT_NAME, limit, offset, parentSuite, nil) ?? ""
            } else {
                urlStringSuites = Constants.urlString(.suitesWithoutParent, Constants.PROJECT_NAME, limit, offset, nil, nil) ?? ""
            }
            
            APIManager.shared.fetchData(from: urlStringSuites, method: Constants.APIType.get.rawValue, token: Constants.TOKEN, modelType: SuitesDataModel.self) { [weak self] (result: Result<SuitesDataModel, Error>) in
                
                switch result {
                case .success(let jsonSuites):
                    self?.changeDataTypeToUniversalizeData(isSuite: true, targetUniversalList: &self!.suitesAndCaseData, suites: jsonSuites.result.entities, testCases: nil)
                    
                case .failure(let error):
                    print(error)
                }
            }
            offset += limit
        } while offset < totalCountOfSuites
    }
    
    private func fetchCasesJSON() {
        let limit = 100
        var offset = 0
        var urlStringCases = ""
        
        repeat {
            if let parentSuite = parentSuite {
                urlStringCases = Constants.urlString(.cases, Constants.PROJECT_NAME, limit, offset, parentSuite, nil) ?? ""
            } else {
                urlStringCases = Constants.urlString(.casesWithoutParent, Constants.PROJECT_NAME, limit, offset, nil, nil) ?? ""
            }
            
            APIManager.shared.fetchData(from: urlStringCases, method: Constants.APIType.get.rawValue, token: Constants.TOKEN, modelType: TestCasesModel.self) { [weak self] (result: Result<TestCasesModel, Error>) in
                
                switch result {
                case .success(let jsonCases):
                    self?.changeDataTypeToUniversalizeData(isSuite: false, targetUniversalList: &self!.suitesAndCaseData, suites: nil, testCases: jsonCases.result.entities)
                    
                case .failure(let error):
                    print(error)
                }
            }
            offset += limit
        } while offset < totalCountOfCases
        
        DispatchQueue.main.async {
            LoadingIndicator.stopLoading()
        }
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
    
    // MARK: - VC funcs
    
    func countOfRows() -> Int {
        suitesAndCaseData.count
    }
}
