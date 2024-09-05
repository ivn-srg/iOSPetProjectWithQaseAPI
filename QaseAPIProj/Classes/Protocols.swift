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

protocol UpdateDataInVCProtocol: AnyObject {
    func updateUI()
}

@objc protocol SwipeTabbarProtocol: AnyObject {
    @objc func swipeBetweenViews(_ gesture: UISwipeGestureRecognizer)
}
