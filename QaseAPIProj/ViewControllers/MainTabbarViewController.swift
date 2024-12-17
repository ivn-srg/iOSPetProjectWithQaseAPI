//
//  MainTabbarViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 25.10.2024.
//

import UIKit

final class MainTabbarViewController: UITabBarController {
    // MARK: - Fields
    
    // MARK: - UI components
    
    // MARK: - LifeCycle
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        
        let firstVC = UINavigationController(rootViewController: ProjectsViewController())
        let secondVC = ProfileViewController()
        
        firstVC.tabBarItem = UITabBarItem(title: "Repository".localized, image: AppTheme.listBulletImage, tag: 0)
        secondVC.tabBarItem = UITabBarItem(title: "Profile".localized, image: AppTheme.personImage, tag: 1)
        
        viewControllers = [firstVC, secondVC]
    }
    // MARK: - other block
}

extension MainTabbarViewController: UITabBarControllerDelegate {
    
}
