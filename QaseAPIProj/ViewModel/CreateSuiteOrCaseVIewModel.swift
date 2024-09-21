//
//  CreateSuiteOrCaseVIewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 21.09.2024.
//

import Foundation

final class CreateSuiteOrCaseViewModel {
    // MARK: - Fields
    weak var delegate: CheckEnablingRBBProtocol?
    var creatingEntityIsSuite: Bool = true
    var creatingTestCase: CreatingTestCase? {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.checkConditionAndToggleRightBarButton()
            }
        }
    }
    var creatingSuite: CreatingSuite? {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.checkConditionAndToggleRightBarButton()
            }
        }
    }
    var isFieldsEmpty = false {
        didSet {
            DispatchQueue.main.async {
                self.emptyFieldsClosure()
            }
        }
    }
    var isEntityWasCreated = false {
        didSet {
            DispatchQueue.main.async {
                self.creatingFinishCallback()
            }
        }
    }
    var creatingFinishCallback: () -> Void = {}
    var emptyFieldsClosure: () -> Void = {}
    
    // MARK: - LifeCycle
    init() {
        self.creatingSuite = CreatingSuite.empty
        self.creatingTestCase = CreatingTestCase.empty
    }
    
    // MARK: - Network work
    func createNewEntity() {
        LoadingIndicator.startLoading()
        if let creatingSuite = creatingSuite, creatingEntityIsSuite {
            isFieldsEmpty = creatingSuite.title.isEmpty
            return
        } else if let creatingTestCase = creatingTestCase, !creatingEntityIsSuite{
            isFieldsEmpty = creatingTestCase.title.isEmpty
            return
        }
        guard let urlString = Constants.getUrlString(
            APIMethod: creatingEntityIsSuite ? .suites : .cases,
            codeOfProject: Constants.PROJECT_NAME,
            limit: nil,
            offset: nil,
            parentSuite: nil,
            caseId: nil
        ) else { return }
        
        if creatingEntityIsSuite {
            guard let creatingSuite = creatingSuite else { return }
            APIManager.shared.createorUpdateEntity(
                newData: creatingSuite,
                from: urlString,
                method: Constants.APIType.post.rawValue,
                modelType: ServerResponse<CreateOrUpdateSuiteModel>.self) {
                    [weak self] (result: Result<ServerResponse<CreateOrUpdateSuiteModel>, Error>) in
                    
                    switch result {
                    case .success(let jsonUpdateResult):
                        self?.isEntityWasCreated = jsonUpdateResult.status
                    case .failure(let error):
                        print(error)
                    }
                    LoadingIndicator.stopLoading()
                }
        } else {
            guard let creatingTestCase = creatingTestCase else { return }
            APIManager.shared.createorUpdateEntity(
                newData: creatingTestCase,
                from: urlString,
                method: Constants.APIType.post.rawValue,
                modelType: ServerResponse<CreateOrUpdateTestCaseModel>.self) {
                    [weak self] (result: Result<ServerResponse<CreateOrUpdateTestCaseModel>, Error>) in
                    
                    switch result {
                    case .success(let jsonUpdateResult):
                        self?.isEntityWasCreated = jsonUpdateResult.status
                    case .failure(let error):
                        print(error)
                    }
                    LoadingIndicator.stopLoading()
                }
        }
    }
}
