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
        LoadingIndicator.startLoading()
        suitesAndCaseData.removeAll()
        getTotalCountOfEntities()
        fetchSuitesJSON()
        fetchCasesJSON()
        LoadingIndicator.stopLoading()
    }
    
    private func getTotalCountOfEntities() {
        guard let urlStringSuites = apiManager.formUrlString(
            APIMethod: .suites,
            codeOfProject: PROJECT_NAME,
            limit: 1,
            offset: 0,
            parentSuite: nil,
            caseId: nil
        ) else { return }
        guard let urlStringCases = apiManager.formUrlString(
            APIMethod: .cases,
            codeOfProject: PROJECT_NAME,
            limit: 1,
            offset: 0,
            parentSuite: parentSuite,
            caseId: nil
        ) else { return }
        
        Task {
            async let countOfSuites = apiManager.performRequest(
                from: urlStringSuites,
                method: .get,
                modelType: SuitesDataModel.self
            )
            async let countOfTestCases = apiManager.performRequest(
                from: urlStringCases,
                method: .get,
                modelType: TestCasesModel.self
            )
            totalCountOfSuites = try await countOfSuites.result.total
            totalCountOfCases = try await parentSuite != nil ? countOfTestCases.result.filtered : countOfTestCases.result.total
        }
    }
    
    private func fetchSuitesJSON() {
        let limit = 100
        var offset = 0
        var urlStringSuites = ""
        
        repeat {
            urlStringSuites = apiManager.formUrlString(
                APIMethod: .suites,
                codeOfProject: PROJECT_NAME,
                limit: limit,
                offset: offset,
                parentSuite: nil,
                caseId: nil
            ) ?? ""
            
            Task {
                let suitesResult = try await apiManager.performRequest(
                    from: urlStringSuites,
                    method: .get,
                    modelType: SuitesDataModel.self
                )
                
                let filteredSuites = parentSuite != nil
                ? suitesResult.result.entities.filter { $0.parentId == parentSuite?.id }
                : suitesResult.result.entities.filter { $0.parentId == nil }
                
                changeDataTypeToUniversalizeData(
                    isSuite: true,
                    targetUniversalList: &suitesAndCaseData,
                    suites: filteredSuites,
                    testCases: nil
                )
            }
            offset += limit
        } while offset < totalCountOfSuites
    }
    
    private func fetchCasesJSON() {
        let limit = 100
        var offset = 0
        var urlStringCases = ""
        
        repeat {
            urlStringCases = apiManager.formUrlString(
                APIMethod: .cases,
                codeOfProject: PROJECT_NAME,
                limit: limit,
                offset: offset,
                parentSuite: parentSuite,
                caseId: nil
            ) ?? ""
            
            Task {
                let testCasesResult = try await apiManager.performRequest(
                    from: urlStringCases,
                    method: .get,
                    modelType: TestCasesModel.self
                )
                let filteredCases = parentSuite != nil
                ? testCasesResult.result.entities.filter { $0.suiteId == parentSuite?.id }
                : testCasesResult.result.entities.filter { $0.suiteId == nil }
                
                changeDataTypeToUniversalizeData(
                    isSuite: false,
                    targetUniversalList: &suitesAndCaseData,
                    suites: nil,
                    testCases: filteredCases
                )
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
