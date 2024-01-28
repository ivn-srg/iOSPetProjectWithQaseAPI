//
//  DeatilTabBarController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit

class DetailTabBarController: UITabBarController {
    
    let openedCaseName = "1F-302"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let generalInfoVC = GeneralDetailCaseViewController()
        let propertiesInfoVC = PropertiesDetailCaseViewController()
        let runsInfolVC = RunsDetailCaseViewController()
        let defectsInfoVC = DefectsDetailCaseViewController()
        
        generalInfoVC.tabBarItem = UITabBarItem(title: "General", image: nil, tag: 0)
        propertiesInfoVC.tabBarItem = UITabBarItem(title: "Properties", image: nil, tag: 1)
        runsInfolVC.tabBarItem = UITabBarItem(title: "Runs", image: nil, tag: 2)
        defectsInfoVC.tabBarItem = UITabBarItem(title: "Defects", image: nil, tag: 3)

        viewControllers = [generalInfoVC, propertiesInfoVC, runsInfolVC, defectsInfoVC]
        
        title = openedCaseName
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .white
    }
    
    
}
