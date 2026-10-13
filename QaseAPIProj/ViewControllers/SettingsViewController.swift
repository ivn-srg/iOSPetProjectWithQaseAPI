//
//  SettingsViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 25.10.2024.
//

import Combine
import SwiftUI
import UIKit

@MainActor
final class SettingsViewController: UIHostingController<SettingsRootView> {
    private let model: SettingsViewModel
    private let navigate: (SettingsRoute, UIViewController) -> Void
    private let onFailure: (String) -> Void
    private let makeTokenController: () -> UIViewController
    private let prepareForChange: @MainActor () async -> Bool
    private var logoutTask: Task<Void, Never>?

    init(
        model: SettingsViewModel,
        onFailure: @escaping (String) -> Void,
        navigate: @escaping (SettingsRoute, UIViewController) -> Void,
        makeTokenController: @escaping () -> UIViewController,
        prepareForChange: @escaping @MainActor () async -> Bool
    ) {
        self.navigate = navigate
        self.onFailure = onFailure
        self.makeTokenController = makeTokenController
        self.model = model
        self.prepareForChange = prepareForChange
        super.init(rootView: SettingsRootView(model: model, preferences: model.preferences))
        rootView = SettingsRootView(
            model: model,
            preferences: model.preferences,
            onRoute: { [weak self] route in self?.show(route) }
        )
        title = "Settings".localized
        navigationItem.largeTitleDisplayMode = .always
    }

    required dynamic init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        model.refreshLanguage()
    }

    private func show(_ route: SettingsRoute) {
        switch route {
        case .appearance:
            navigate(.appearance, self)
        case .language:
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            Task { [weak self] in
                let opened = await UIApplication.shared.open(url)
                if !opened, let self {
                    UIAlertController.showSimpleAlert(
                        on: self,
                        title: "Error".localized,
                        message: "Could not open iOS Settings".localized
                    )
                }
            }
        case .token:
            present(makeTokenController(), animated: true)
        case .cache:
            navigate(.cache, self)
        case .about:
            navigate(.about, self)
        case .logout:
            signOut()
        }
    }

    private func signOut() {
        guard logoutTask == nil else { return }
        logoutTask = Task { [weak self] in
            guard let self else { return }
            defer { self.logoutTask = nil }
            guard await self.prepareForChange(), !Task.isCancelled else { return }
            do { try await self.model.auth.logout() }
            catch {
                self
                    .onFailure((error is AuthOperationError ?
                            "Signed out, but cached data could not be cleared." :
                            "Could not complete sign out")
                        .localized)
            }
        }
    }

    deinit { logoutTask?.cancel() }
}

@MainActor
final class TokenReplacementController: UIHostingController<TokenReplacementView> {
    private let model: TokenReplacementViewModel
    private var observation: AnyCancellable?

    init(model: TokenReplacementViewModel) {
        self.model = model
        super.init(rootView: TokenReplacementView(model: model))
        title = "API token".localized
        navigationItem.largeTitleDisplayMode = .never
        let cancelButton = UIBarButtonItem(
            title: "Cancel".localized,
            style: .plain,
            target: self,
            action: #selector(cancel)
        )
        cancelButton.accessibilityIdentifier = AccessibilityID.settingsTokenCancel.identifier
        navigationItem.leftBarButtonItem = cancelButton
        let saveButton = UIBarButtonItem(
            title: "Save".localized,
            style: .plain,
            target: self,
            action: #selector(save)
        )
        if #available(iOS 26.0, *) { saveButton.style = .prominent }
        saveButton.accessibilityIdentifier = AccessibilityID.settingsTokenSave.identifier
        saveButton.isEnabled = model.canSave
        navigationItem.rightBarButtonItem = saveButton
        observation = model.$token.combineLatest(model.$isSaving).sink { [weak self] token, saving in
            self?.navigationItem.rightBarButtonItem?.isEnabled = !saving && !token
                .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    required dynamic init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    @objc private func cancel() { model.cancel() }
    @objc private func save() { model.save() }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        model.stop()
    }
}
