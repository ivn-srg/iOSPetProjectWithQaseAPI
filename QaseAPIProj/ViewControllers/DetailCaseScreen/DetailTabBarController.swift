//
//  DeatilTabBarController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit
import Foundation

class DetailTabBarController: UITabBarController {
    // MARK: - Fields
    let viewModel: DetailTabbarControllerViewModel
    
    // MARK: - UI components
    private lazy var alertController: UIAlertController = {
        let alertC = UIAlertController(
            title: "Data Has been saved ✅",
            message: "Your changes for \(Constants.PROJECT_NAME)-\(viewModel.caseId) test case with successfully saved",
            preferredStyle: .alert
        )
        let action = UIAlertAction(title: "OK", style: .cancel)
        alertC.addAction(action)
        return alertC
    }()
    
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
        viewModel.updatingFinishCallback = {
            self.present(self.alertController, animated: true)
        }
        configureView()
        setupGestures()
        delegate = self
        checkConditionAndToggleRightBarButton()
    }
    
    // MARK: - View Configuration
    func configureView() {
        let generalInfoVC = GeneralDetailCaseViewController(vm: self.viewModel)
        let propertiesInfoVC = PropertiesDetailCaseViewController(vm: self.viewModel)
        let defectsInfoVC = DefectsDetailCaseViewController(vm: self.viewModel)
        
        generalInfoVC.tabBarItem = UITabBarItem(title: "General", image: nil, tag: 0)
        propertiesInfoVC.tabBarItem = UITabBarItem(title: "Properties", image: nil, tag: 1)
        defectsInfoVC.tabBarItem = UITabBarItem(title: "Defects", image: nil, tag: 2)
        
        viewControllers = [generalInfoVC, propertiesInfoVC, defectsInfoVC]
        
        title = "\(Constants.PROJECT_NAME)-\(viewModel.caseId)"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .white
    }
}

extension DetailTabBarController: UITabBarControllerDelegate {
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        print("tabBarItem didSelect")
    }
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("tabBarController didSelect")
    }
}

extension DetailTabBarController: DetailTestCaseProtocol {
    // MARK: - updating UI for VCs
    func updateUI() {
        DispatchQueue.main.async {
            self.title = "\(Constants.PROJECT_NAME)-\(self.viewModel.caseId)"
            if let viewControllers = self.viewControllers {
                for viewCN in viewControllers {
                    guard let viewCN = viewCN as? DetailTestCaseProtocol else { continue }
                    viewCN.updateUI()
                }
            }
            LoadingIndicator.stopLoading()
        }
    }
    
    // MARK: - setuping gestures for VCs
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
    
    // MARK: - setuping save bar buttons into VC's navItem
    func checkConditionAndToggleRightBarButton() {
        let shouldShowButton = viewModel.testCase != viewModel.changedTestCase
        
        if shouldShowButton {
            let rightBarButton = UIBarButtonItem(title: "Save",
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(rightBarButtonTapped))
            navigationItem.setRightBarButton(rightBarButton, animated: true)
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    @objc func rightBarButtonTapped() {
        viewModel.updateTestCaseData()
    }
}
