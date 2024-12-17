//
//  AlertViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 23.10.2024.
//

import UIKit

extension UIAlertController {
    static func showSimpleAlert(
        on viewController: UIViewController,
        title: String = "errorTitle".localized,
        message: String
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
    
    static func showConfirmAlert(
        on viewController: UIViewController,
        title: String,
        message: String,
        completionHandler: @escaping (UIAlertAction) -> Void,
        cancelCompetionHandler: @escaping (UIAlertAction) -> Void
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "Cancel".localized, style: .cancel, handler: cancelCompetionHandler))
        alert.addAction(.init(title: "OK", style: .destructive, handler: completionHandler))
        viewController.present(alert, animated: true)
    }
}
