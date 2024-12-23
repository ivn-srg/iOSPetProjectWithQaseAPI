//
//  Protocols.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 03.05.2024.
//

import Foundation
import UIKit

protocol NextViewControllerPusher: AnyObject {
    func pushToNextVC(to item: Int?)
}

protocol UpdateTableViewProtocol: AnyObject {
    func updateTableView()
}

@objc protocol DetailTestCaseProtocol: AnyObject {
    func updateUI()
    @objc func swipeBetweenViews(_ gesture: UISwipeGestureRecognizer)
}

protocol CheckEnablingRBBProtocol: AnyObject {
    func checkConditionAndToggleRightBarButton()
}

protocol MenuDataSource {
    static var dataSource: [MenuItem] { get }
    var menuItem: MenuItem { get }
}

protocol UpdatableEntityProtocol {
    var testCase: TestEntity? { get set }
    var changedTestCase: TestEntity? { get set }
    func updateValue<T>(for field: FieldType, value: T)
}

extension UpdatableEntityProtocol {
    var testCase: TestEntity? {
        get { nil }
        set { }
    }
    
    var changedTestCase: TestEntity? {
        get { nil }
        set { }
    }
}
