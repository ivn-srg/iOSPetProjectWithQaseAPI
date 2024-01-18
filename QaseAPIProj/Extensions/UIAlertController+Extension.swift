//
//  UIAlertController+Extension.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 17.01.2024.
//

import UIKit

extension UIViewController {
    func showErrorAlert(titleAlert: String, messageAlert: String) {
        let ac = UIAlertController(title: titleAlert, message: messageAlert, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}
