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
        UIImage(systemName: "arrow.up")?
            .withRenderingMode(.alwaysTemplate)
            .withTintColor(.red, renderingMode: .alwaysOriginal)
    }()
    static let circleImage = UIImage(systemName: "circle")
    static let chevronDownImage: UIImage? = {
        UIImage(systemName: "arrow.down")?
            .withRenderingMode(.alwaysTemplate)
            .withTintColor(.systemGreen, renderingMode: .alwaysOriginal)
    }()
    static let xmarkCircleFillImage = UIImage(systemName: "xmark.circle.fill")?.withRenderingMode(.alwaysTemplate)
    static let minusImage = UIImage(systemName: "minus")
    static let exitImage: UIImage? = {
        UIImage(systemName: "rectangle.portrait.and.arrow.right")?
            .withRenderingMode(.alwaysTemplate)
            .withTintColor(.red, renderingMode: .alwaysOriginal)
    }()
    static let listBulletImage = UIImage(systemName: "list.bullet.rectangle.fill")
    static let personImage = UIImage(systemName: "person.crop.circle.fill")
    static let nosignImage: UIImage? = {
        UIImage(systemName: "nosign")?
            .withRenderingMode(.alwaysTemplate)
            .withTintColor(.red, renderingMode: .alwaysOriginal)
    }()
    static let chevronDoubleUpImage: UIImage? = {
        UIImage(systemName: "chevron.up.2")?
            .withRenderingMode(.alwaysTemplate)
            .withTintColor(.red, renderingMode: .alwaysOriginal)
    }()
    static let chevronDoubleDownImage = UIImage(systemName: "chevron.down.2")
    static let arrowUpImage: UIImage? = {
        UIImage(systemName: "arrow.up")?
            .withRenderingMode(.alwaysTemplate)
            .withTintColor(.red, renderingMode: .alwaysOriginal)
    }()
    static let arrowDownImage: UIImage? = {
        UIImage(systemName: "arrow.down")?
            .withRenderingMode(.alwaysTemplate)
            .withTintColor(.systemGreen, renderingMode: .alwaysOriginal)
    }()
    static let computerImage = UIImage(systemName: "desktopcomputer")
    static let gearDoubleFillImage = UIImage(systemName: "gearshape.2.fill")
    static let apiImage = UIImage(systemName: "externaldrive.connected.to.line.below.fill")
    static let gearshapeImage: UIImage? = {
        UIImage(systemName: "gearshape.fill")?
            .withRenderingMode(.alwaysTemplate)
            .withTintColor(.blue, renderingMode: .alwaysOriginal)
    }()
    static let trashImage = UIImage(systemName: "trash")
    
    // colors
    static let fioletColor = UIColor(named: "primaryUColor") ?? UIColor.purple
    static let bgPrimaryColor = UIColor(named: "primaryBackground") ?? UIColor.white
    static let bgSecondaryColor = UIColor(named: "secondaryBackground") ?? UIColor.white
    static let bgThirdthColor = UIColor(named: "thirdthBackground") ?? UIColor.white
    static let textColor = UIColor(named: "text") ?? UIColor.white
    static let additionTintColor = UIColor(named: "additionTintColor") ?? UIColor.white
    
    // paddings
    static let horizontalPadding: CGFloat = 20
}
