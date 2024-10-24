//
//  AlertViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 23.10.2024.
//

import UIKit

extension UIAlertController {
    static func showErrorAlert(
        on viewController: UIViewController,
        title: String = String(localized: "errorTitle"),
        message: String
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
}
