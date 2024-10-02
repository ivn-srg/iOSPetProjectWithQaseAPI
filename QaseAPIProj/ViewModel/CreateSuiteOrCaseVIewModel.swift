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
        LoadingIndicator.startLoading()
        
        Task {
            if creatingEntityIsSuite {
                let response = try await APIManager.shared.createorUpdateEntity(
                    newData: creatingSuite,
                    from: urlString,
                    method: Constants.APIType.post.rawValue,
                    modelType: ServerResponseModel<CreateOrUpdateSuiteModel>.self
                )
                isEntityWasCreated = response.status
            } else {
                let response = try await APIManager.shared.createorUpdateEntity(
                    newData: creatingTestCase,
                    from: urlString,
                    method: Constants.APIType.post.rawValue,
                    modelType: ServerResponseModel<CreateOrUpdateTestCaseModel>.self
                )
                isEntityWasCreated = response.status
            }
            LoadingIndicator.stopLoading()
        }
    }
}
