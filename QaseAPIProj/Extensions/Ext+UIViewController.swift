//
//  Ext+UIViewController.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 24.10.2024.
//

import UIKit

extension UIViewController {
    // Universalized func for error handling
    func executeWithErrorHandling(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            UIAlertController.showErrorAlert(on: self, message: error.localizedDescription)
        }
    }
}
