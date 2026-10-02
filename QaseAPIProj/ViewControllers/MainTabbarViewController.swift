//
//  MainTabbarViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 25.10.2024.
//

import UIKit

final class MainTabbarViewController: UITabBarController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let homeVC = UINavigationController(rootViewController: HomeViewController())
        let repositoryVC = UINavigationController(rootViewController: ProjectsViewController())
        let testRunsVC = UINavigationController(rootViewController: TestRunsViewController())
        let settingsVC = UINavigationController(rootViewController: SettingsViewController())
        
        repositoryVC.tabBarItem = UITabBarItem(title: "Repository".localized, image: AppTheme.repositoryImage, tag: 1)
        homeVC.tabBarItem = UITabBarItem(title: "Home".localized, image: AppTheme.homeImage, tag: 0)
        testRunsVC.tabBarItem = UITabBarItem(title: "In progress".localized, image: AppTheme.playCircleImage, tag: 2)
        settingsVC.tabBarItem = UITabBarItem(title: "Settings".localized, image: AppTheme.gearshapeFillImage, tag: 3)
        
        setViewControllers(
            [homeVC, repositoryVC, testRunsVC, settingsVC],
            animated: true
        )
    }
}
