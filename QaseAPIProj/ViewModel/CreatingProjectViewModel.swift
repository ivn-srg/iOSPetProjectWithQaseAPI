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
            Task { @MainActor in
                delegate?.checkConditionAndToggleRightBarButton()
            }
        }
    }

    var isFieldsEmpty = false {
        didSet {
            if isFieldsEmpty {
                Task { @MainActor in
                    showErrorClosure(
                        "Not enough".localized,
                        "Probably you didn't fill all fields, check it, please".localized
                    )
                }
            }
        }
    }

    var isEntityWasCreated = false {
        didSet {
            if isEntityWasCreated { creatingFinishCallback() }
            else { showErrorClosure("Error".localized, "Something went wrong".localized) }
        }
    }

    var creatingFinishCallback: () -> Void = {}
    var showErrorClosure: (String, String) -> Void = { (_, _) in }

    private let network: NetworkManager
    private let session: SessionContext
    private let originStamp: SessionStamp

    // MARK: - LifeCycle
    init(
        network: NetworkManager = ApiServiceConfiguration.shared.apiService,
        session: SessionContext? = nil
    ) {
        self.network = network
        self.session = session ?? .shared
        originStamp = self.session.capture()
        self.creatingProject = .init()
    }

    // MARK: - Network work
    func createNewProject() async throws {
        guard session.isCurrent(originStamp) else { throw CancellationError() }
        if creatingProject.isEmpty {
            isFieldsEmpty = true
            return
        }

        let stamp = originStamp
        guard let urlString = network.composeURL(for: .project, urlComponents: nil, queryItems: nil)
        else { throw API.NetError.invalidURL }

        LoadingIndicator.startLoading()

        defer { LoadingIndicator.stopLoading() }
        let response = try await network.performRequest(
            with: creatingProject,
            from: urlString,
            method: .post,
            modelType: ServerResponseModel<CreateOrUpdateProjectModel>.self
        )

        guard session.isCurrent(stamp), !Task.isCancelled else { throw CancellationError() }
        isEntityWasCreated = response.status?.value ?? false
        LoadingIndicator.stopLoading()
    }
}

extension CreatingProjectViewModel: UpdatableEntityProtocol {
    func updateValue<T>(for field: FieldType, value: T) {
        guard let value = value as? String else { return }
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
