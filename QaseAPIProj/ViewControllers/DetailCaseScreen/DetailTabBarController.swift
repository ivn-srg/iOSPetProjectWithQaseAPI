//
//  DeatilTabBarController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit

class DetailTabBarController: UITabBarController {
    
    let projectId: String
    let caseId: Int
    let vm: DetailTabbarControllerViewModel
    var testCase: TestEntity? = nil
    
    init(projectId: String, caseId: Int, vm: DetailTabbarControllerViewModel) {
        self.projectId = projectId
        self.caseId = caseId
        self.vm = vm
        
        self.vm.caseId = caseId
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
        vm.updateDataSource()
        
        let generalInfoVC = GeneralDetailCaseViewController(vm: DetailTabbarControllerViewModel())
        let propertiesInfoVC = PropertiesDetailCaseViewController()
        let runsInfolVC = RunsDetailCaseViewController()
        let defectsInfoVC = DefectsDetailCaseViewController()
        
        generalInfoVC.tabBarItem = UITabBarItem(title: "General", image: nil, tag: 0)
        propertiesInfoVC.tabBarItem = UITabBarItem(title: "Properties", image: nil, tag: 1)
        runsInfolVC.tabBarItem = UITabBarItem(title: "Runs", image: nil, tag: 2)
        defectsInfoVC.tabBarItem = UITabBarItem(title: "Defects", image: nil, tag: 3)
        
        viewControllers = [generalInfoVC, propertiesInfoVC, runsInfolVC, defectsInfoVC]
        
        title = "\(projectId)-\(caseId)"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .white
    }
    
    
}
