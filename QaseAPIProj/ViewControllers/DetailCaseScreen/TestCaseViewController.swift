//
//  DeatilTabBarController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit
import Foundation

final class TestCaseViewController: UIViewController {
    // MARK: - Fields
    let viewModel: DetailTabbarControllerViewModel
    private var viewControllers = [UIViewController]()
    
    // MARK: - UI components
    private lazy var tabbar: UITabBar = {
        let tb = UITabBar()
        tb.translatesAutoresizingMaskIntoConstraints = false
        tb.delegate = self
        return tb
    }()
    
    private lazy var containerView: UIView = {
        let cv = UIView()
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    // MARK: - Lifecycle
    
    init(caseUniqueKey: String) {
        self.viewModel = DetailTabbarControllerViewModel(caseUniqueKey: caseUniqueKey)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.delegate = self
        executeWithErrorHandling {
            try await self.viewModel.fetchCaseDataJSON()
        }
        viewModel.updatingFinishCallback = {
            UIAlertController.showSimpleAlert(
                on: self, title: "Data has been saved ✅".localized,
                message: String(
                    format: "Your changes for %@-%d test case with successfully saved".localized,
                    PROJECT_NAME, self.viewModel.caseId
                )
            )
        }
        viewModel.checkDataChanged = {
            self.checkConditionAndToggleRightBarButton()
        }
        
        setupTopTabBar()
        configureView()
        setupInitialViewController()
        setupGestures()
        checkConditionAndToggleRightBarButton()
    }
    
    // MARK: - View Configuration
    func setupTopTabBar() {
        let generalInfoVC = GeneralDetailCaseViewController(vm: viewModel)
        let propertiesInfoVC = PropertiesDetailCaseViewController(vm: viewModel)
        viewControllers = [generalInfoVC, propertiesInfoVC]
        
        let tabbarItems = [
            UITabBarItem(title: "General".localized, image: nil, tag: 0),
            UITabBarItem(title: "Properties".localized, image: nil, tag: 1),
        ]
        
        tabbar.items = tabbarItems.map {
            $0.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -6)
            $0.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 15)], for: .normal)
            return $0
        }
        
        tabbar.backgroundColor = AppTheme.bgPrimaryColor
        tabbar.barTintColor = AppTheme.bgPrimaryColor
        tabbar.selectedItem = tabbar.items?.first
        
        view.addSubview(tabbar)
        tabbar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.horizontalEdges.equalTo(view.snp.horizontalEdges)
            $0.height.equalTo(30)
        }
    }
    
    private func configureView() {
        view.addSubview(containerView)
        
        containerView.snp.makeConstraints {
            $0.top.equalTo(tabbar.snp.bottom)
            $0.horizontalEdges.equalTo(view.snp.horizontalEdges)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        title = "\(PROJECT_NAME)-\(viewModel.caseId)"
    }
    
    private func setupInitialViewController() {
        guard let firstVC = viewControllers.first else { return }
        addChildVC(firstVC)
    }
    
    private func addChildVC(_ viewController: UIViewController) {
        addChild(viewController)
        containerView.addSubview(viewController.view)
        viewController.view.frame = containerView.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewController.didMove(toParent: self)
    }
    
    private func removeCurrentViewController() {
        if let currentChild = children.first {
            currentChild.willMove(toParent: nil)
            currentChild.view.removeFromSuperview()
            currentChild.removeFromParent()
        }
    }
    
    private func changeCurrentView(to item: UITabBarItem?) {
        guard let item = item else { return }
        
        removeCurrentViewController()
        switch item.tag {
        case 0:
            addChildVC(viewControllers[0])
        case 1:
            addChildVC(viewControllers[1])
        case 2:
            addChildVC(viewControllers[2])
        default:
            break
        }
    }
}

// MARK: - UITabBarDelegate
extension TestCaseViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        changeCurrentView(to: item)
    }
}

// MARK: - DetailTestCaseProtocol
extension TestCaseViewController: DetailTestCaseProtocol {
    func updateUI() {
        Task { @MainActor in
            title = "\(PROJECT_NAME)-\(viewModel.caseId)"
            for viewC in viewControllers {
                guard let viewC = viewC as? DetailTestCaseProtocol else { continue }
                viewC.updateUI()
            }
        }
    }
    
    // MARK: - setuping gestures for VCs
    private func setupGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipeBetweenViews(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeBetweenViews(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }
    
    @objc func swipeBetweenViews(_ gesture: UISwipeGestureRecognizer) {
        let tabsCount = viewControllers.count
        
        if let selectedItem = tabbar.selectedItem, let tabbarItems = tabbar.items {
            if gesture.direction == .right {
                if selectedItem.tag > 0 {
                    tabbar.selectedItem = tabbarItems[selectedItem.tag - 1]
                } else if selectedItem.tag == 0 {
                    tabbar.selectedItem = tabbarItems[tabsCount - 1]
                }
                changeCurrentView(to: tabbar.selectedItem)
            } else if gesture.direction == .left {
                if selectedItem.tag < tabsCount - 1 {
                    tabbar.selectedItem = tabbarItems[selectedItem.tag + 1]
                } else if selectedItem.tag == tabsCount - 1 {
                    tabbar.selectedItem = tabbarItems[0]
                }
                changeCurrentView(to: tabbar.selectedItem)
            }
        }
    }
}

extension TestCaseViewController: CheckEnablingRBBProtocol {
    // MARK: - setuping save bar buttons into VC's navItem
    func checkConditionAndToggleRightBarButton() {
        let shouldShowButton = viewModel.testCase != viewModel.changedTestCase
        
        if shouldShowButton {
            let rightBarButton = UIBarButtonItem(title: "Save".localized,
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(rightBarButtonTapped))
            navigationItem.setRightBarButton(rightBarButton, animated: true)
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    @objc func rightBarButtonTapped() {
        executeWithErrorHandling {
            try await self.viewModel.updateTestCaseData()
        }
    }
}
