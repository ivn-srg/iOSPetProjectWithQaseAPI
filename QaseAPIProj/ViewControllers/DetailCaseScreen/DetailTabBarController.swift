//
//  DeatilTabBarController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit

class DetailTabBarController: UITabBarController {
    
    let viewModel: DetailTabbarControllerViewModel
    var testCaseData: TestEntity? = nil
    
    init(vm: DetailTabbarControllerViewModel) {
        self.viewModel = vm
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func loadView() {
        super.loadView()
        
        configureView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func configureView() {
        viewModel.updateDataSource()
        
        let generalInfoVC = GeneralDetailCaseViewController(vm: viewModel)
        let propertiesInfoVC = PropertiesDetailCaseViewController()
        let runsInfolVC = RunsDetailCaseViewController()
        let defectsInfoVC = DefectsDetailCaseViewController()
        
        generalInfoVC.tabBarItem = UITabBarItem(title: "General", image: nil, tag: 0)
        propertiesInfoVC.tabBarItem = UITabBarItem(title: "Properties", image: nil, tag: 1)
        runsInfolVC.tabBarItem = UITabBarItem(title: "Runs", image: nil, tag: 2)
        defectsInfoVC.tabBarItem = UITabBarItem(title: "Defects", image: nil, tag: 3)
        
        viewControllers = [generalInfoVC, propertiesInfoVC, runsInfolVC, defectsInfoVC]
        
        title = "\(Constants.PROJECT_NAME)-\(viewModel.caseId)"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .white
    }
}
