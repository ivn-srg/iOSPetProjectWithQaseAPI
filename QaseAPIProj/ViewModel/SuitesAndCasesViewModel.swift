//
//  SuitesAndCasesViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 03.05.2024.
//

import Foundation

final class SuitesAndCasesViewModel {
    
    // MARK: - Fields
    weak var delegate: UpdateTableViewProtocol?
    var parentSuite: ParentSuite?
    var isLoading = false
    var suitesAndCaseData = [SuiteAndCaseData]() {
        didSet {
            delegate?.updateTableView()
        }
    }
    private let realmDb = RealmManager.shared
    private var totalCountOfSuites = 0
    private var totalCountOfCases = 0
    private var countOfFetchedCases = 0
    private var hasMoreCases = true
    
    // MARK: - lifecycle
    
    init(delegate: UpdateTableViewProtocol? = nil, parentSuite: ParentSuite? = nil) {
        self.delegate = delegate
        self.parentSuite = parentSuite
    }
    
    // MARK: - Network funcs
    
    func requestEntitiesData(place: PlaceOfRequest = .start) async throws(APIError) {
        switch place {
        case .start, .refresh:
            await MainActor.run {
                LoadingIndicator.startLoading()
            }
            
            resetPaginationArgs()
            suitesAndCaseData.removeAll()
            try getTotalCountOfSuites()
            try fetchSuitesJSON()
            try fetchCasesJSON()
            
            await MainActor.run {
                LoadingIndicator.stopLoading()
            }
        case .continuos:
            try fetchCasesJSON()
        }
    }
    
    func deleteEntity(at index: Int) throws(APIError) {
        let entity = suitesAndCaseData[index]
        guard let urlString = apiManager.formUrlString(
            APIMethod: entity.isSuites ? .suites : .cases,
            codeOfProject: PROJECT_NAME,
            suiteId: entity.isSuites ? entity.id : nil,
            caseId: !entity.isSuites ? entity.id : nil
        )
        else { throw .invalidURL }
        
        Task { @MainActor in
            LoadingIndicator.startLoading()
        }
        
        Task {
            let deletingResult = try await apiManager.performRequest(
                from: urlString,
                method: .delete,
                modelType: SharedResponseModel.self
            )
            if deletingResult.status {
                suitesAndCaseData.remove(at: index)
            }
            
            await MainActor.run {
                LoadingIndicator.stopLoading()
            }
        }
    }
    
    // MARK: - private funcs
    
    private func getTotalCountOfSuites() throws(APIError) {
        guard let urlStringSuites = apiManager.formUrlString(
            APIMethod: .suites,
            codeOfProject: PROJECT_NAME,
            limit: 1,
            offset: 0
        ) else { throw .invalidURL }
        
        Task {
            let countOfSuites = try await apiManager.performRequest(
                from: urlStringSuites,
                method: .get,
                modelType: SuitesDataModel.self
            )
            totalCountOfSuites = countOfSuites.result.total
        }
    }
    
    private func fetchSuitesJSON() throws(APIError) {
        let limit = 50
        var offset = 0
        
        if let testSuites = realmDb.getTestEntities(by: parentSuite, testEntitiesType: .suites) {
            suitesAndCaseData.append(contentsOf: testSuites)
            return
        }
        
        repeat {
            guard let urlStringSuites = apiManager.formUrlString(
                APIMethod: .suites,
                codeOfProject: PROJECT_NAME,
                limit: limit,
                offset: offset
            ) else { throw .invalidURL }
            
            Task {
                let suitesResult = try await apiManager.performRequest(
                    from: urlStringSuites,
                    method: .get,
                    modelType: SuitesDataModel.self
                )
                
                let filteredSuites = parentSuite != nil
                ? suitesResult.result.entities.filter { $0.parentId == parentSuite!.id }
                : suitesResult.result.entities.filter { $0.parentId == nil }
                
                changeDataTypeToUniversalData(
                    isSuite: true,
                    targetUniversalList: &suitesAndCaseData,
                    suites: filteredSuites,
                    testCases: nil
                )
            }
            offset += limit
        } while offset < totalCountOfSuites
    }
    
    private func fetchCasesJSON() throws(APIError) {
        let limit = 50
        guard let urlStringCases = apiManager.formUrlString(
            APIMethod: .cases,
            codeOfProject: PROJECT_NAME,
            limit: limit,
            offset: countOfFetchedCases,
            parentSuite: parentSuite
        ) else { throw .invalidURL }
        
        if let testCases = realmDb.getTestEntities(by: parentSuite, testEntitiesType: .cases) {
            suitesAndCaseData.append(contentsOf: testCases)
            return
        }
        
        if hasMoreCases && !isLoading {
            Task {
                isLoading = true
                let testCasesResult = try await apiManager.performRequest(
                    from: urlStringCases,
                    method: .get,
                    modelType: TestCasesModel.self
                )
                
                let filteredSuites = parentSuite == nil
                ? testCasesResult.result.entities.filter { $0.suiteId == nil }
                : testCasesResult.result.entities
                
                totalCountOfCases = totalCountOfCases == 0
                ? testCasesResult.result.total
                : totalCountOfCases
                
                changeDataTypeToUniversalData(
                    isSuite: false,
                    targetUniversalList: &suitesAndCaseData,
                    suites: nil,
                    testCases: filteredSuites
                )
                
                countOfFetchedCases += limit
                hasMoreCases = countOfFetchedCases < totalCountOfCases
                isLoading = false
            }
        }
    }
    
    private func changeDataTypeToUniversalData(
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
            guard let suites = suites, !suites.isEmpty else { return }
            
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
                let _ = realmDb.saveTestEntity(universalItem)
            }
        } else {
            guard let testCases = testCases, !testCases.isEmpty else { return }
            
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
                let _ = realmDb.saveTestEntity(universalItem)
            }
        }
    }
    
    private func resetPaginationArgs() {
        totalCountOfSuites = 0
        totalCountOfCases = 0
        countOfFetchedCases = 0
        hasMoreCases = true
    }
    
    // MARK: - VC funcs
    func countOfRows() -> Int {
        suitesAndCaseData.count
    }
}
