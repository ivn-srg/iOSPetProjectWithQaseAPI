//
//  Assets.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 09.01.2024.
//

import SwiftUI
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

    static let xmarkCircleFillImage = UIImage(systemName: "xmark.circle.fill")?
        .withRenderingMode(.alwaysTemplate)
    static let minusImage = UIImage(systemName: "minus")
    static let exitImage: UIImage? = {
        UIImage(systemName: "rectangle.portrait.and.arrow.right")?
            .withRenderingMode(.alwaysTemplate)
            .withTintColor(.red, renderingMode: .alwaysOriginal)
    }()

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
    static let trashImage = UIImage(systemName: "trash")
    static let repositoryImage = UIImage(systemName: "internaldrive.fill")
    static let homeImage = UIImage(systemName: "house.fill")
    static let playCircleImage = UIImage(systemName: "play.circle") ?? UIImage()
    static let textDocumentImage = UIImage(systemName: "text.document") ?? UIImage()
    static let squareStackImage = UIImage(systemName: "square.stack.3d.up") ?? UIImage()
    static let bugImage = UIImage(systemName: "ladybug") ?? UIImage()

    // colors
    static let fioletColor = UIColor(named: "primaryUColor") ?? UIColor.purple
    static let bgPrimaryColor = UIColor(named: "primaryBackground") ?? UIColor.white
    static let bgSecondaryColor = UIColor(named: "secondaryBackground") ?? UIColor.white
    static let bgThirdthColor = UIColor(named: "thirdthBackground") ?? UIColor.white
    static let textColor = UIColor(named: "text") ?? UIColor.white
    static let additionTintColor = UIColor(named: "additionTintColor") ?? UIColor.white

    // paddings
    static let horizontalPadding: CGFloat = 20

    enum Space {
        static let tiny: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let regular: CGFloat = 16
        static let screen: CGFloat = 20
        static let section: CGFloat = 24
        static let large: CGFloat = 32
    }

    enum Radius {
        static let badge: CGFloat = 8
        static let control: CGFloat = 12
        static let card: CGFloat = 16
        static let hero: CGFloat = 24
    }

    enum Size {
        static let actionIcon: CGFloat = 22
        static let touch: CGFloat = 44
        static let button: CGFloat = 48
        static let metric: CGFloat = 92
        static let progress: CGFloat = 104
        static let content: CGFloat = 680
    }

    enum Typography {
        static let screen: Font = .system(.title, design: .default, weight: .bold)
        static let section: Font = .system(.title3, design: .default, weight: .semibold)
        static let card: Font = .system(.headline)
        static let body: Font = .system(.body)
        static let metadata: Font = .system(.footnote)
        static let badge: Font = .system(.caption, design: .default, weight: .medium)
        static let metric: Font = .system(.title, design: .default, weight: .bold)

        static var screenUIKit: UIFont { scaled(size: 28, style: .title1, weight: .bold) }
        static var sectionUIKit: UIFont { scaled(size: 20, style: .title3, weight: .semibold) }
        static var cardUIKit: UIFont { scaled(size: 17, style: .headline, weight: .semibold) }
        static var bodyUIKit: UIFont { scaled(size: 17, style: .body, weight: .regular) }
        static var metadataUIKit: UIFont { scaled(size: 13, style: .footnote, weight: .regular) }

        private static func scaled(size: CGFloat, style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
            UIFontMetrics(forTextStyle: style).scaledFont(for: .systemFont(ofSize: size, weight: weight))
        }
    }

    enum Materials {
        static let card: Material = .regular
        static let cardUIKit: UIBlurEffect.Style = .systemMaterial
    }

    enum Shadows {
        static let low = UIColor { traits in
            UIColor.black.withAlphaComponent(traits.userInterfaceStyle == .dark ? 0.24 : 0.08) }

        static let medium = UIColor { traits in
            UIColor.black.withAlphaComponent(traits.userInterfaceStyle == .dark ? 0.36 : 0.12) }

        static let lowRadius: CGFloat = 8
        static let lowOffset: CGFloat = 2
        static let mediumRadius: CGFloat = 24
        static let mediumOffset: CGFloat = 8
    }

    enum Palette {
        static let buttonStart = adaptive(0x6757F5, 0x6757F5)
        static let buttonEnd = adaptive(0x8068FF, 0x8068FF)
        static let buttonContrastOverlay = 0.12
        static let canvas = adaptive(0xFFFFFF, 0x000000)
        static let surface = adaptive(0xFFFFFF, 0x1C1C1F)
        static let secondarySurface = adaptive(0xF4F5F7, 0x2C2C2D)
        static let tertiarySurface = adaptive(0xECEEF2, 0x34343A)
        static let text = adaptive(0x111113, 0xF7F7F8)
        static let secondaryText = adaptive(0x6F7179, 0xA5A7AE)
        static let tertiaryText = adaptive(0x92949D, 0x7D8089)
        static let border = adaptive(0xE6E7EB, 0x34343A)
        static let strongBorder = adaptive(0xD4D6DC, 0x484850)
        static let accent = adaptive(0x6757F5, 0x8577FF)
        static let secondaryAccent = adaptive(0x8068FF, 0xA59BFF)
        static let info = adaptive(0x0B5FCC, 0x5AA2FF)
        static let success = adaptive(0x147A32, 0x4EC46D)
        static let warning = adaptive(0xA64B00, 0xFF9F43)
        static let danger = adaptive(0xD92D20, 0xFF6B6B)
        static let infoBackground = adaptive(0xE8F1FF, 0x0B2B55)
        static let successBackground = adaptive(0xEAF7ED, 0x123A20)
        static let warningBackground = adaptive(0xFFF1E5, 0x4A280B)
        static let dangerBackground = adaptive(0xFDECEA, 0x4A1717)

        private static func adaptive(_ light: UInt32, _ dark: UInt32) -> UIColor {
            UIColor { traits in
                let value = traits.userInterfaceStyle == .dark ? dark : light
                return UIColor(
                    red: CGFloat((value >> 16) & 255) / 255,
                    green: CGFloat((value >> 8) & 255) / 255,
                    blue: CGFloat(value & 255) / 255,
                    alpha: 1
                )
            }
        }
    }
}

extension UIImage {
    func paint(to color: UIColor) -> UIImage {
        withTintColor(color, renderingMode: .alwaysOriginal)
    }
}
