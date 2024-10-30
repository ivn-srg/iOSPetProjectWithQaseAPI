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

protocol IdenticalEntitiesProtocol: AnyObject {
    // TODO: - Make universalize protocol for creating and updating entities
    var title: String { get set }
    var description: String { get set }
    var preconditions: String { get set }
    var postconditions: String { get set }
    var code: String { get set }
    var parentId: Int? { get set }
}

extension IdenticalEntitiesProtocol {
    var postconditions: String { return "" }
    var code: String { return "" }
    var parentId: Int? { return nil }
}

protocol MenuDataSource {
    static var dataSource: [MenuItem] { get }
}
