//
//  RootViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 25.10.2024.
//

import UIKit

final class RootViewController: UIViewController {
    private var currentViewController: UIViewController?
    private let makeContent: () -> UIViewController
    private let session: SessionContext

    init(session: SessionContext, makeContent: @escaping () -> UIViewController) {
        self.session = session
        self.makeContent = makeContent
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthorizationStatusChange(_:)),
            name: .didChangeAuthStatus,
            object: session
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSettingsFailure(_:)),
            name: .settingsOperationFailed,
            object: session
        )
        updateRootViewController()
    }

    func updateRootViewController() {
        let newViewController = makeContent()

        if let currentVC = currentViewController {
            currentVC.dismiss(animated: false)
            currentVC.willMove(toParent: nil)
            currentVC.view.removeFromSuperview()
            currentVC.removeFromParent()
        }

        addChild(newViewController)
        view.addSubview(newViewController.view)
        newViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            newViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            newViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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
