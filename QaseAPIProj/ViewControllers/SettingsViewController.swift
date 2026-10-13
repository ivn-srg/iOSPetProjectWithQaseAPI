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
    private let prepareForChange: @MainActor () async -> Bool
    private var logoutTask: Task<Void, Never>?

    init(prepareForChange: @escaping @MainActor () async -> Bool = { true }) {
        let model = SettingsViewModel(preferences: .shared)
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
            push(AppearanceSettingsView(preferences: model.preferences), title: "Theme".localized)
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
            let tokenModel = TokenReplacementViewModel(auth: model.auth, prepareForChange: prepareForChange)
            let controller = TokenReplacementController(model: tokenModel)
            let navigation = UINavigationController(rootViewController: controller)
            navigation.navigationBar.tintColor = AppTheme.Palette.accent
            navigation.modalPresentationStyle = .fullScreen
            tokenModel.onClose = { [weak navigation] in navigation?.dismiss(animated: true) }
            present(navigation, animated: true)
        case .cache:
            push(CacheSettingsView(model: model), title: "Manage cache".localized)
        case .about:
            push(AboutSettingsView(model: model), title: "About application".localized)
        case .logout:
            signOut()
        }
    }

    private func push<V: View>(_ view: V, title: String) {
        let controller = UIHostingController(rootView: view)
        controller.title = title
        controller.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(controller, animated: true)
    }

    private func signOut() {
        guard logoutTask == nil else { return }
        logoutTask = Task { [weak self] in
            guard let self else { return }
            defer { self.logoutTask = nil }
            guard await self.prepareForChange(), !Task.isCancelled else { return }
            do { try await self.model.auth.logout() }
            catch {
                NotificationCenter.default.post(
                    name: .settingsOperationFailed,
                    object: nil,
                    userInfo: ["message": "Could not complete sign out"
                        .localized]
                )
            }
        }
    }

    deinit { logoutTask?.cancel() }
}

@MainActor
private final class TokenReplacementController: UIHostingController<TokenReplacementView> {
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
        cancelButton.accessibilityIdentifier = "settings.token.cancel"
        navigationItem.leftBarButtonItem = cancelButton
        let saveButton = UIBarButtonItem(
            title: "Save".localized,
            style: .done,
            target: self,
            action: #selector(save)
        )
        saveButton.accessibilityIdentifier = "settings.token.save"
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
