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
    var parentSuite: ParentSuite?
    private var totalCountOfSuites = 0
    private var totalCountOfCases = 0
    
    var suitesAndCaseData = [SuiteAndCaseData]() {
        didSet {
            delegate?.updateTableView()
        }
    }
    
    // MARK: - lifecycle
    
    init(delegate: UpdateTableViewProtocol? = nil, parentSuite: ParentSuite? = nil) {
        self.delegate = delegate
        self.parentSuite = parentSuite
    }
    
    // MARK: - Network funcs
    
    func requestEntitiesData() {
        suitesAndCaseData.removeAll()
        getTotalCountOfEntities()
        fetchSuitesJSON()
        fetchCasesJSON()
    }
    
    private func getTotalCountOfEntities() {
        guard let urlStringSuites = Constants.getUrlString(
            APIMethod: .suites,
            codeOfProject: Constants.PROJECT_NAME,
            limit: 1,
            offset: 0,
            parentSuite: nil,
            caseId: nil
        ) else { return }
        guard let urlStringCases = Constants.getUrlString(
            APIMethod: .cases,
            codeOfProject: Constants.PROJECT_NAME,
            limit: 1,
            offset: 0,
            parentSuite: parentSuite,
            caseId: nil
        ) else { return }
        
        DispatchQueue.main.async {
            LoadingIndicator.startLoading()
        }
        
        APIManager.shared.fetchData(
            from: urlStringSuites,
            method: Constants.APIType.get.rawValue,
            modelType: SuitesDataModel.self)
        { [weak self] (result: Result<SuitesDataModel, Error>) in
            switch result {
            case .success(let jsonSuites):
                self?.totalCountOfSuites = jsonSuites.result.total
            case .failure(let error):
                print(error)
                break
            }
        }
        
        APIManager.shared.fetchData(
            from: urlStringCases,
            method: Constants.APIType.get.rawValue,
            modelType: TestCasesModel.self)
        { [weak self] (result: Result<TestCasesModel, Error>) in
            switch result {
            case .success(let jsonCases):
                self?.totalCountOfCases = self?.parentSuite != nil ? jsonCases.result.filtered : jsonCases.result.total
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
            urlStringSuites = Constants.getUrlString(
                APIMethod: .suites,
                codeOfProject: Constants.PROJECT_NAME,
                limit: limit,
                offset: offset,
                parentSuite: nil,
                caseId: nil
            ) ?? ""
            
            APIManager.shared.fetchData(
                from: urlStringSuites,
                method: Constants.APIType.get.rawValue,
                modelType: SuitesDataModel.self)
            { [weak self] (result: Result<SuitesDataModel, Error>) in
                
                switch result {
                case .success(let jsonSuites):
                    let filteredSuites = self?.parentSuite != nil
                    ? jsonSuites.result.entities.filter { $0.parentId == self?.parentSuite?.id }
                    : jsonSuites.result.entities.filter { $0.parentId == nil }
                    self?.changeDataTypeToUniversalizeData(
                        isSuite: true,
                        targetUniversalList: &self!.suitesAndCaseData,
                        suites: filteredSuites,
                        testCases: nil
                    )
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
            urlStringCases = Constants.getUrlString(
                APIMethod: .cases,
                codeOfProject: Constants.PROJECT_NAME,
                limit: limit,
                offset: offset,
                parentSuite: parentSuite,
                caseId: nil
            ) ?? ""
            
            APIManager.shared.fetchData(
                from: urlStringCases,
                method: Constants.APIType.get.rawValue,
                modelType: TestCasesModel.self)
            { [weak self] (result: Result<TestCasesModel, Error>) in
                
                switch result {
                case .success(let jsonCases):
                    let filteredCases = self?.parentSuite != nil
                    ? jsonCases.result.entities.filter { $0.suiteId == self?.parentSuite?.id }
                    : jsonCases.result.entities.filter { $0.suiteId == nil }
                    self?.changeDataTypeToUniversalizeData(
                        isSuite: false,
                        targetUniversalList: &self!.suitesAndCaseData,
                        suites: nil,
                        testCases: filteredCases
                    )
                case .failure(let error):
                    print(error)
                }
            }
            offset += limit
        } while offset < totalCountOfCases
    }
    
    private func changeDataTypeToUniversalizeData(
        isSuite: Bool,
        targetUniversalList: inout [SuiteAndCaseData],
        suites: [SuiteEntity]?,
        testCases: [TestEntity]?
    ) {
        func appendElement(element: SuiteAndCaseData, to list: inout [SuiteAndCaseData]) {
            if element.isSuites {
                if !list.contains(where: {
                    $0.isSuites && $0.id == element.id
                }) {
                    list.append(element)
                }
            } else {
                if !list.contains(where: {
                    !$0.isSuites && $0.id == element.id
                }) {
                    list.append(element)
                }
            }
        }
        if isSuite {
            guard let suites = suites else { return }
            
            for suite in suites {
                let universalItem = SuiteAndCaseData(
                    isSuite: true,
                    id: suite.id,
                    title: suite.title,
                    description: suite.itemDescription,
                    preconditions: suite.preconditions,
                    parentId: suite.parentId,
                    caseCount: suite.casesCount
                )
                appendElement(element: universalItem, to: &targetUniversalList)
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
                    parentId: nil,
                    caseCount: nil,
                    priority: testCase.priority,
                    automation: testCase.automation,
                    suiteId: testCase.suiteId
                )
                appendElement(element: universalItem, to: &targetUniversalList)
            }
        }
    }
    
    // MARK: - VC funcs
    
    func countOfRows() -> Int {
        suitesAndCaseData.count
    }
}
