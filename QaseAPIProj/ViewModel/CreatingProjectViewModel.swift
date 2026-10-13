//
//  CreatingProjectViewModel.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.09.2024.
//

import Foundation

@MainActor
final class CreatingProjectViewModel {
    // MARK: - Fields
    weak var delegate: CheckEnablingRBBProtocol?
    var creatingProject: Project {
        didSet {
            delegate?.checkConditionAndToggleRightBarButton()
        }
    }

    private(set) var isSaving = false { didSet { delegate?.checkConditionAndToggleRightBarButton() } }
    private var baseline = Project()
    var hasUnsavedChanges: Bool {
        creatingProject.title != baseline.title || creatingProject.code != baseline.code || creatingProject
            .description != baseline.description
    }

    func discardDraft() {
        guard !isSaving else { return }
        creatingProject = baseline
    }

    var isFieldsEmpty = false {
        didSet {
            if isFieldsEmpty {
                showErrorClosure(
                    "Not enough".localized,
                    "Probably you didn't fill all fields, check it, please".localized
                )
            }
        }
    }

    var isEntityWasCreated = false {
        didSet {
            if isEntityWasCreated { creatingFinishCallback() }

        }
    }

    var creatingFinishCallback: () -> Void = {}
    var showErrorClosure: (String, String) -> Void = { (_, _) in }

    private let network: NetworkManager
    private let session: SessionContext
    private let originStamp: SessionStamp

    // MARK: - LifeCycle
    init(network: NetworkManager, session: SessionContext) {
        self.network = network
        self.session = session
        originStamp = self.session.capture()
        self.creatingProject = .init()
    }

    // MARK: - Network work
    func createNewProject() async throws {
        guard !isSaving, session.isCurrent(originStamp) else { throw CancellationError() }
        if creatingProject.isEmpty {
            isFieldsEmpty = true
            return
        }

        isEntityWasCreated = false
        let stamp = originStamp
        guard let urlString = network.composeURL(for: .project, urlComponents: nil, queryItems: nil)
        else { throw API.NetError.invalidURL }

        isSaving = true
        defer { isSaving = false }
        let response = try await network.performRequest(
            with: creatingProject,
            from: urlString,
            method: .post,
            modelType: ServerResponseModel<CreateOrUpdateProjectModel>.self
        )

        guard session.isCurrent(stamp), !Task.isCancelled else { throw CancellationError() }
        guard response.status?.value == true else { throw API.NetError.invalidRequest("Create failed") }
        baseline = creatingProject
        isEntityWasCreated = true
    }
}

extension CreatingProjectViewModel: FormValueUpdating {

    func updateValue(for field: FieldType, value: FormFieldValue) {
        guard let value = value.text else { return }
        switch field {
        case .title:
            creatingProject.title = value
        case .description:
            creatingProject.description = value
        case .code:
            creatingProject.code = value
        default: break
        }
    }
}
