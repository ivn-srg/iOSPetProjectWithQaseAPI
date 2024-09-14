//
//  DeatilTabBarController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit

class DetailTabBarController: UITabBarController {
    // MARK: - Fields
    let viewModel: DetailTabbarControllerViewModel
    
    // MARK: - UI components
    private lazy var saveRightBarButtonImage: UIImageView = {
        let imageV = UIImageView()
        imageV.image = AppTheme.checkMarkImage
        imageV.tintColor = viewModel.isTestCaseDataEditing ? .blue : .gray
        imageV.contentMode = .scaleAspectFit
        return imageV
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
        addOrRemoveRightBarButton(tabBarController: tabBarController, navItem: navigationItem)
    }
    
    // MARK: - private funcs
    private func addOrRemoveRightBarButton(tabBarController: UITabBarController?, navItem: UINavigationItem) {
        guard let tabBarController = tabBarController, let selectedViewController = tabBarController.selectedViewController else { return }
        var rightBarButton: UIBarButtonItem
        
        navigationItem.rightBarButtonItems?.removeAll()
        
        switch selectedViewController {
        case is GeneralDetailCaseViewController:
            rightBarButton = UIBarButtonItem(
                image: saveRightBarButtonImage.image,
                style: .done,
                target: self,
                action: #selector(viewModel.saveChangedData)
            )
            navigationItem.rightBarButtonItems?.append(rightBarButton)
        case is PropertiesDetailCaseViewController:
            fallthrough
        default:
            rightBarButton =  UIBarButtonItem()
        }
    }
}

extension DetailTabBarController: UITabBarControllerDelegate {
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        print("tabBarItem didSelect")
    }
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("tabBarController didSelect")
        addOrRemoveRightBarButton(tabBarController: tabBarController, navItem: navigationItem)
    }
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
