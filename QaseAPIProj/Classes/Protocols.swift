//
//  Protocols.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 03.05.2024.
//

import Foundation
import UIKit

@MainActor
protocol NextViewControllerPusher: AnyObject {
    func pushToNextVC(to item: Int?)
}

@MainActor
protocol UpdateTableViewProtocol: AnyObject {
    func updateTableView()
}

@MainActor
@objc protocol DetailTestCaseProtocol: AnyObject {
    func updateUI()
}

@MainActor
protocol CheckEnablingRBBProtocol: AnyObject {
    func checkConditionAndToggleRightBarButton()
}

protocol MenuDataSource {
    @MainActor static var dataSource: [MenuItem] { get }
    @MainActor var menuItem: MenuItem { get }
}

@MainActor
protocol FormValueUpdating: AnyObject {
    func updateValue(for field: FieldType, value: FormFieldValue)
}

@MainActor
protocol UpdatableEntityProtocol: FormValueUpdating {
    var formCase: TestCaseEntity? { get }
}

enum FormFieldValue: Sendable {
    case text(String)
    case selection(Int)
    case toggle(Bool)

    var text: String? { if case .text(let value) = self { return value }
        return nil }

    var selectionID: Int? { if case .selection(let value) = self { return value }
        return nil }

    var toggle: Bool? { if case .toggle(let value) = self { return value }
        return nil }
}

extension FormValueUpdating {
    func updateValue(for field: FieldType, value: String) { updateValue(for: field, value: .text(value)) }
    func updateValue(for field: FieldType, value: Int) { updateValue(for: field, value: .selection(value)) }
    func updateValue(for field: FieldType, value: Bool) { updateValue(for: field, value: .toggle(value)) }
    func updateValue(for field: FieldType, value: MenuItem) { updateValue(
        for: field,
        value: .selection(value.id)
    ) }
}
