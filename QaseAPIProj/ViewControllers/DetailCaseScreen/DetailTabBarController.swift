//
//  DeatilTabBarController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit

class DetailTabBarController: UITabBarController, UpdateDataInVCProtocol {
    
    let viewModel: DetailTabbarControllerViewModel
    
    // MARK: - Lifecycle
    
    init(caseId: Int) {
        self.viewModel = DetailTabbarControllerViewModel(caseId: caseId)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.fetchCaseDataJSON()
        configureView()
    }
    
    func configureView() {
        
        let generalInfoVC = GeneralDetailCaseViewController(vm: self.viewModel)
        let propertiesInfoVC = PropertiesDetailCaseViewController(vm: self.viewModel)
        let runsInfolVC = RunsDetailCaseViewController(vm: self.viewModel)
        let defectsInfoVC = DefectsDetailCaseViewController(vm: self.viewModel)
        
        generalInfoVC.tabBarItem = UITabBarItem(title: "General", image: nil, tag: 0)
        propertiesInfoVC.tabBarItem = UITabBarItem(title: "Properties", image: nil, tag: 1)
        runsInfolVC.tabBarItem = UITabBarItem(title: "Runs", image: nil, tag: 2)
        defectsInfoVC.tabBarItem = UITabBarItem(title: "Defects", image: nil, tag: 3)
        
        viewControllers = [generalInfoVC, propertiesInfoVC, runsInfolVC, defectsInfoVC]
        
        title = "\(Constants.PROJECT_NAME)-\(viewModel.caseId)"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .white
    }
    
    func updateUI() {
        DispatchQueue.main.async {
            self.setViewControllers(self.viewControllers, animated: true)
            LoadingIndicator.stopLoading()
        }
    }
}
