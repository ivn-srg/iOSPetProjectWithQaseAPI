//
//  SuitesAndCasesViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 03.05.2024.
//

import Foundation

final class TestEntitiesViewModel {
    
    // MARK: - Fields
    weak var delegate: UpdateTableViewProtocol?
    var parentSuite: ParentSuite?
    var isLoading = false
    var testEntitiesData = [TestListEntity]() {
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
    func requestEntitiesData(place: PlaceOfRequest) async throws {
        switch place {
        case .start, .refresh:
            await MainActor.run {
                LoadingIndicator.startLoading()
            }
            
            resetPaginationArgs()
            loadCachedData()
            
            do {
                try await fetchAndSyncData()
            } catch {
                print("Error syncing data: \(error)")
            }
            
            await MainActor.run {
                LoadingIndicator.stopLoading()
            }
        case .continuos:
            try await fetchCasesJSON()
        }
    }
    
    func deleteEntity(at index: Int) async throws(API.NetError) {
        let entity = testEntitiesData[index]
        
        guard
            let urlString = apiManager.composeURL(for: entity.isSuite ? .suites : .cases,
                                                  urlComponents: [PROJECT_NAME, String(entity.id)], queryItems: nil)
        else { throw .invalidURL }
        
        Task { @MainActor in
            LoadingIndicator.startLoading()
        }
        
        let deletingResult = try await apiManager.performRequest(
            with: nil, from: urlString,
            method: .delete,
            modelType: SharedResponseModel.self
        )
        
        if deletingResult.status {
            let deletedEntity = testEntitiesData.remove(at: index)
            let _ = realmDb.deleteEntity(deletedEntity)
        }
        
        await MainActor.run {
            LoadingIndicator.stopLoading()
        }
    }
    
    // MARK: - private funcs
    private func loadCachedData() {
        if let cachedSuites = realmDb.getTestEntities(by: parentSuite, testEntitiesType: .suites),
           let cachedCases = realmDb.getTestEntities(by: parentSuite, testEntitiesType: .cases) {
            var combinedData = [TestListEntity]()
            combinedData.append(contentsOf: cachedSuites)
            combinedData.append(contentsOf: cachedCases)
            testEntitiesData = combinedData
        }
    }
    
    private func fetchAndSyncData() async throws {
        try await fetchSuitesJSON()
        try await fetchCasesJSON()
    }
    
    private func fetchSuitesJSON() async throws {
        if testEntitiesData.isEmpty,
           let testSuites = realmDb.getTestEntities(by: parentSuite, testEntitiesType: .suites),
           !testSuites.isEmpty {
            testEntitiesData.append(contentsOf: testSuites)
            return
        }
        
        let _ = try await {
            guard
                let urlStringSuites = apiManager.composeURL(for: .suites, urlComponents: [PROJECT_NAME], queryItems: [.limit: 1, .offset: 0])
            else { throw API.NetError.invalidURL }
            
            let countOfSuites = try await apiManager.performRequest(
                with: nil, from: urlStringSuites,
                method: .get,
                modelType: SuitesDataModel.self
            )
            
            totalCountOfSuites = countOfSuites.result.total
        }()
        
        var offset = 0
        
        repeat {
            guard
                let urlStringSuites = apiManager.composeURL(for: .suites, urlComponents: [PROJECT_NAME], queryItems: [.limit: Constants.LIMIT_OF_REQUEST, .offset: offset])
            else { throw API.NetError.invalidURL }
            
            let suitesResult = try await apiManager.performRequest(
                with: nil, from: urlStringSuites,
                method: .get,
                modelType: SuitesDataModel.self
            )
            
            let filteredSuites = parentSuite != nil
            ? suitesResult.result.entities.filter { $0.parentId == parentSuite!.id }
            : suitesResult.result.entities.filter { $0.parentId == nil }
            
            let _ = realmDb.saveTestEntities(filteredSuites)
            updateDataList(with: filteredSuites)
            
            offset += Constants.LIMIT_OF_REQUEST
        } while offset < totalCountOfSuites
    }
    
    private func fetchCasesJSON() async throws(API.NetError) {
        guard
            let urlStringCases = apiManager.composeURL(
                for: .cases, urlComponents: [PROJECT_NAME],
                queryItems: [
                    .suiteId: parentSuite?.id,
                    .limit: Constants.LIMIT_OF_REQUEST,
                    .offset: countOfFetchedCases
                ]
            )
        else { throw .invalidURL }
        
        if hasMoreCases && !isLoading {
            isLoading = true
            let testCasesResult = try await apiManager.performRequest(
                with: nil, from: urlStringCases,
                method: .get,
                modelType: TestCasesModel.self
            )
            
            let filteredSuites = parentSuite == nil
            ? testCasesResult.result.entities.filter { $0.suiteId == nil }
            : testCasesResult.result.entities
            
            totalCountOfCases = totalCountOfCases == 0
            ? testCasesResult.result.total
            : totalCountOfCases
            
            let newCases = filteredSuites.map {
                TestListEntity(testCase: $0)
            }
            
            let _ = realmDb.saveTestEntities(newCases)
            updateDataList(with: newCases)
            
            countOfFetchedCases += Constants.LIMIT_OF_REQUEST
            hasMoreCases = countOfFetchedCases < totalCountOfCases
            isLoading = false
        }
    }
    
    private func updateDataList(with newData: [TestListEntity]) {
        for newItem in newData {
            if let existingIndex = testEntitiesData.firstIndex(where: { $0.id == newItem.id && $0.isSuite == newItem.isSuite }) {
                testEntitiesData[existingIndex] = newItem
            } else {
                testEntitiesData.append(newItem)
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
        testEntitiesData.count
    }
}
