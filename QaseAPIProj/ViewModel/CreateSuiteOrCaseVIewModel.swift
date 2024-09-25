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
    var creatingTestCase: CreatingTestCase {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.checkConditionAndToggleRightBarButton()
            }
        }
    }
    var creatingSuite: CreatingSuite {
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
        isFieldsEmpty = creatingEntityIsSuite ? creatingSuite.title.isEmpty : creatingTestCase.title.isEmpty
        if isFieldsEmpty { return }
            
        guard let urlString = Constants.getUrlString(
            APIMethod: creatingEntityIsSuite ? .suites : .cases,
            codeOfProject: Constants.PROJECT_NAME,
            limit: nil,
            offset: nil,
            parentSuite: nil,
            caseId: nil
        ) else { return }
        
        if creatingEntityIsSuite {
            APIManager.shared.createorUpdateEntity(
                newData: creatingSuite,
                from: urlString,
                method: Constants.APIType.post.rawValue,
                modelType: ServerResponseModel<CreateOrUpdateSuiteModel>.self) {
                    [weak self] (result: Result<ServerResponseModel<CreateOrUpdateSuiteModel>, Error>) in
                    
                    switch result {
                    case .success(let jsonUpdateResult):
                        self?.isEntityWasCreated = jsonUpdateResult.status
                    case .failure(let error):
                        print(error)
                    }
                    LoadingIndicator.stopLoading()
                }
        } else {
            APIManager.shared.createorUpdateEntity(
                newData: creatingTestCase,
                from: urlString,
                method: Constants.APIType.post.rawValue,
                modelType: ServerResponseModel<CreateOrUpdateTestCaseModel>.self) {
                    [weak self] (result: Result<ServerResponseModel<CreateOrUpdateTestCaseModel>, Error>) in
                    
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
