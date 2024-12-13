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
            selector: #selector(handleAuthorizationStatusChange),
            name: .didChangeAuthStatus,
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
    
    @objc private func handleAuthorizationStatusChange() {
        updateRootViewController()
    }
}
