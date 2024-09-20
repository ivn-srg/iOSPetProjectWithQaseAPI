//
//  Assets.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 09.01.2024.
//

import UIKit

enum AppTheme {
    // images
    static let checkMarkImage: UIImage = UIImage(systemName: "checkmark") ?? UIImage()
    static let LogoApp = UIImage(named: "FullLogo.png")
    static let notAutomationImage = UIImage(systemName: "hand.raised")
    static let toBeAutomationImage = UIImage(systemName: "person.2.badge.gearshape")
    static let automationImage = UIImage(systemName: "gearshape.fill")
    static let highPriorityImage = UIImage(systemName: "arrow.up")
    static let mediumPriorityImage = UIImage(systemName: "circle")
    static let lowPriorityImage = UIImage(systemName: "arrow.down")
    static let xmarkCircleFillImage = UIImage(systemName: "xmark.circle.fill")
    static let noPriorityImage = UIImage(systemName: "minus")
    // colors
    static let fioletColor = UIColor(red: 0.31, green: 0.27, blue: 0.86, alpha: 1)
}

// MARK: - Shared UI Components
func showAlertController(on vc: UIViewController, title: String, message: String) {
    let alert = UIAlertController(
        title: title,
        message: message,
        preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    vc.present(alert, animated: true)
}