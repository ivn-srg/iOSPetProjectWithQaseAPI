//
//  DeatilTabBarController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit

class DetailTabBarController: UITabBarController {
    
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
        
        viewModel.delegate = self
        viewModel.fetchCaseDataJSON()
        configureView()
        setupGestures()
        delegate = self
    }
    
    // MARK: - View Configuration
    
    func configureView() {
        let generalInfoVC = GeneralDetailCaseViewController(vm: self.viewModel)
        let propertiesInfoVC = PropertiesDetailCaseViewController(vm: self.viewModel)
        let runsInfoVC = RunsDetailCaseViewController(vm: self.viewModel)
        let defectsInfoVC = DefectsDetailCaseViewController(vm: self.viewModel)
        
        generalInfoVC.tabBarItem = UITabBarItem(title: "General", image: nil, tag: 0)
        propertiesInfoVC.tabBarItem = UITabBarItem(title: "Properties", image: nil, tag: 1)
        runsInfoVC.tabBarItem = UITabBarItem(title: "Runs", image: nil, tag: 2)
        defectsInfoVC.tabBarItem = UITabBarItem(title: "Defects", image: nil, tag: 3)
        
        viewControllers = [generalInfoVC, propertiesInfoVC, runsInfoVC, defectsInfoVC]
        
        title = "\(Constants.PROJECT_NAME)-\(viewModel.caseId)"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .white
    }
}

extension DetailTabBarController: UITabBarControllerDelegate {
}

extension DetailTabBarController: UpdateDataInVCProtocol {
    func updateUI() {
        DispatchQueue.main.async {
            self.title = "\(Constants.PROJECT_NAME)-\(self.viewModel.caseId)"
            if let viewControllers = self.viewControllers {
                for viewCN in viewControllers {
                    guard let viewCN = viewCN as? UpdateDataInVCProtocol else { continue }
                    viewCN.updateUI()
                }
            }
            LoadingIndicator.stopLoading()
        }
    }
}

extension DetailTabBarController: SwipeTabbarProtocol {
    private func setupGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipeBetweenViews(_:)))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeBetweenViews(_:)))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
    }
    
    @objc func swipeBetweenViews(_ gesture: UISwipeGestureRecognizer) {
        if let tabsCount = viewControllers?.count {
            if gesture.direction == .right {
                if selectedIndex > 0 {
                    selectedIndex -= 1
                } else if selectedIndex == 0 {
                    selectedIndex = tabsCount - 1
                }
            } else if gesture.direction == .left {
                if selectedIndex < tabsCount - 1 {
                    selectedIndex += 1
                } else if selectedIndex == tabsCount - 1 {
                    selectedIndex = 0
                }
            }
        }
    }
}
