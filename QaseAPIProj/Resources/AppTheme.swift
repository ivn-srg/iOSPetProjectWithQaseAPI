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
    static let exitImage = UIImage(systemName: "rectangle.portrait.and.arrow.right")
    static let listBulletImage = UIImage(systemName: "list.bullet.rectangle.fill")
    static let personImage = UIImage(systemName: "person.crop.circle.fill")
    // colors
    static let fioletColor = UIColor(named: "primary") ?? UIColor.purple
    static let bgPrimaryColor = UIColor(named: "primaryBackground") ?? UIColor.white
    static let bgSecondaryColor = UIColor(named: "secondaryBackground") ?? UIColor.white
    static let bgThirdthColor = UIColor(named: "thirdthBackground") ?? UIColor.white
    static let textColor = UIColor(named: "text") ?? UIColor.white
}

// MARK: - Shared UI Components
func showAlertController(on vc: UIViewController, title: String, message: String, handler: ((UIAlertAction) -> Void)? = nil) {
    let alert = UIAlertController(
        title: title,
        message: message,
        preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: handler))
    vc.present(alert, animated: true)
}
