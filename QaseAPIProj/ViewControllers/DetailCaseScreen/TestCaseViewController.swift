//
//  DeatilTabBarController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 18.01.2024.
//

import UIKit
import Foundation

class TestCaseViewController: UIViewController {
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
            UIAlertController.showSimpleAlert(
                on: self, title: "Data Has been saved ✅",
                message: "Your changes for \(PROJECT_NAME)-\(self.viewModel.caseId) test case with successfully saved"
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
        tabbar.items = [
            UITabBarItem(title: "General".localized, image: nil, tag: 0),
            UITabBarItem(title: "Properties".localized, image: nil, tag: 1),
            UITabBarItem(title: "Defects".localized, image: nil, tag: 2)
        ]
        tabbar.selectedItem = tabbar.items?.first
        
        view.addSubview(tabbar)
        tabbar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.horizontalEdges.equalTo(view.safeAreaLayoutGuide.snp.horizontalEdges)
            $0.height.equalTo(20)
        }
    }
    
    func configureView() {
        let generalInfoVC = GeneralDetailCaseViewController(vm: viewModel)
        let propertiesInfoVC = PropertiesDetailCaseViewController(vm: viewModel)
        let defectsInfoVC = DefectsDetailCaseViewController(vm: viewModel)
        viewControllers = [generalInfoVC, propertiesInfoVC, defectsInfoVC]
        
        view.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.top.equalTo(tabbar.snp.bottom)
            $0.horizontalEdges.equalTo(view.safeAreaLayoutGuide.snp.horizontalEdges)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        title = "\(PROJECT_NAME)-\(viewModel.caseId)"
    }
    
    private func setupInitialViewController() {
        let firstVC = GeneralDetailCaseViewController(vm: viewModel)
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
}

extension TestCaseViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        print("tabBarItem didSelect")
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
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("tabBarController didSelect")
    }
}

extension TestCaseViewController: DetailTestCaseProtocol {
    // MARK: - updating UI for VCs
    func updateUI() {
        Task { @MainActor in
            title = "\(PROJECT_NAME)-\(self.viewModel.caseId)"
            for viewCN in viewControllers {
                guard let viewCN = viewCN as? DetailTestCaseProtocol else { continue }
                viewCN.updateUI()
            }
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
        let tabsCount = viewControllers.count
//        if gesture.direction == .right {
//            if selectedIndex > 0 {
//                selectedIndex -= 1
//            } else if selectedIndex == 0 {
//                selectedIndex = tabsCount - 1
//            }
//        } else if gesture.direction == .left {
//            if selectedIndex < tabsCount - 1 {
//                selectedIndex += 1
//            } else if selectedIndex == tabsCount - 1 {
//                selectedIndex = 0
//            }
//        }
    }
}

extension TestCaseViewController: CheckEnablingRBBProtocol {
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
