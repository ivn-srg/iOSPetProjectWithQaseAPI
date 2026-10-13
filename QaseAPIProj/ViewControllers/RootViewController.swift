//
//  RootViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 25.10.2024.
//

import UIKit

final class RootViewController: UIViewController {
    private var currentViewController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthorizationStatusChange(_:)),
            name: .didChangeAuthStatus,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsFailure(_:)),
            name: .settingsOperationFailed,
            object: nil
        )
        updateRootViewController()
    }

    func updateRootViewController() {
        let authManager = AuthManager.shared
        let isUserLoggedIn = authManager.isUserLoggedIn()
        let token = authManager.getAuthToken()

        let newViewController: UIViewController
        if let token = token, !token.isEmpty, isUserLoggedIn {
            newViewController = MainTabbarViewController()
        } else {
            newViewController = AuthViewController()
        }

        if let currentVC = currentViewController {
            currentVC.dismiss(animated: false)
            currentVC.willMove(toParent: nil)
            currentVC.view.removeFromSuperview()
            currentVC.removeFromParent()
        }

        addChild(newViewController)
        view.addSubview(newViewController.view)
        newViewController.view.frame = view.bounds
        newViewController.didMove(toParent: self)
        currentViewController = newViewController
    }

    @objc private func handleAuthorizationStatusChange(_ notification: Notification) {
        updateRootViewController()
        if notification.userInfo?["cacheCleanupFailed"] as? Bool == true {
            showSettingsError("The API token was updated, but old cached data could not be cleared."
                .localized)
        }
    }

    @objc private func handleSettingsFailure(_ notification: Notification) {
        if let message = notification.userInfo?["message"] as? String { showSettingsError(message) }
    }

    private func showSettingsError(_ message: String) {
        Task { @MainActor [weak self] in
            guard let self, self.presentedViewController == nil else { return }
            UIAlertController.showSimpleAlert(on: self, title: "Error".localized, message: message)
        }
    }
}
