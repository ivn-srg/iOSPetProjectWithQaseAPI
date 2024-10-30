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
    static let handRaisedImage = UIImage(systemName: "hand.raised")
    static let personWithGearshapeImage = UIImage(systemName: "person.2.badge.gearshape.fill")
    static let gearshapeFillImage = UIImage(systemName: "gearshape.fill")
    static let chevronUpImage: UIImage? = {
        let image = UIImage(systemName: "arrow.up")
        image?.withTintColor(.red, renderingMode: .alwaysOriginal)
        return image
    }()
    static let circleImage = UIImage(systemName: "circle")
    static let chevronDownImage: UIImage? = {
        let image = UIImage(systemName: "arrow.down")
        image?.withTintColor(.systemGreen, renderingMode: .alwaysOriginal)
        return image
    }()
    static let xmarkCircleFillImage = UIImage(systemName: "xmark.circle.fill")
    static let minusImage = UIImage(systemName: "minus")
    static let exitImage: UIImage? = {
        let image = UIImage(systemName: "rectangle.portrait.and.arrow.right")
        image?.withTintColor(.red, renderingMode: .alwaysOriginal)
        return image
    }()
    static let listBulletImage = UIImage(systemName: "list.bullet.rectangle.fill")
    static let personImage = UIImage(systemName: "person.crop.circle.fill")
    static let nosignImage: UIImage? = {
        let image = UIImage(systemName: "nosign")
        image?.withTintColor(.red, renderingMode: .alwaysOriginal)
        return image
    }()
    static let chevronDoubleUpImage: UIImage? = {
        let image = UIImage(systemName: "chevron.up.2")
        image?.withTintColor(.red, renderingMode: .alwaysOriginal)
        return image
    }()
    static let chevronDoubleDownImage = UIImage(systemName: "chevron.down.2")
    static let arrowUpImage: UIImage? = {
        let image = UIImage(systemName: "arrow.up")
        image?.withTintColor(.red, renderingMode: .alwaysOriginal)
        return image
    }()
    static let arrowDownImage: UIImage? = {
        let image = UIImage(systemName: "arrow.down")
        image?.withTintColor(.systemGreen, renderingMode: .alwaysOriginal)
        return image
    }()
    static let computerImage = UIImage(systemName: "desktopcomputer")
    static let gearDoubleFillImage = UIImage(systemName: "gearshape.2.fill")
    static let apiImage = UIImage(systemName: "externaldrive.connected.to.line.below.fill")
    static let gearshapeImage: UIImage? = {
        let image = UIImage(systemName: "gearshape.fill")
        image?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        return image
    }()
    
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
