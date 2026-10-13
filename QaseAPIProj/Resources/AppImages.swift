import SwiftUI
import UIKit

enum AppSymbol: String, CaseIterable, Sendable {
    case playFill = "play.fill"
    case gearshape = "gearshape"
    case handPointUpLeft = "hand.point.up.left"
    case arrowDown = "arrow.down"
    case arrowTriangle2Circlepath = "arrow.triangle.2.circlepath"
    case arrowUp = "arrow.up"
    case checkmark = "checkmark"
    case checkmarkCircleFill = "checkmark.circle.fill"
    case chevronDown = "chevron.down"
    case chevronDown2 = "chevron.down.2"
    case chevronLeft = "chevron.left"
    case chevronRight = "chevron.right"
    case chevronUp2 = "chevron.up.2"
    case circle = "circle"
    case circleDashed = "circle.dashed"
    case circleLefthalfFilled = "circle.lefthalf.filled"
    case clock = "clock"
    case desktopcomputer = "desktopcomputer"
    case doc = "doc"
    case docTextMagnifyingglass = "doc.text.magnifyingglass"
    case equal = "equal"
    case eye = "eye"
    case eyeSlash = "eye.slash"
    case exclamationmark = "exclamationmark"
    case exclamationmarkCircle = "exclamationmark.circle"
    case exclamationmarkTriangle = "exclamationmark.triangle"
    case externaldrive = "externaldrive"
    case externaldriveConnectedToLineBelowFill = "externaldrive.connected.to.line.below.fill"
    case folder = "folder"
    case folderFill = "folder.fill"
    case gearshape2Fill = "gearshape.2.fill"
    case gearshapeFill = "gearshape.fill"
    case globe = "globe"
    case hammer = "hammer"
    case handRaised = "hand.raised"
    case houseFill = "house.fill"
    case infoCircle = "info.circle"
    case internaldriveFill = "internaldrive.fill"
    case key = "key"
    case ladybug = "ladybug"
    case line3HorizontalDecreaseCircle = "line.3.horizontal.decrease.circle"
    case lineHorizontal3 = "line.horizontal.3"
    case magnifyingglass = "magnifyingglass"
    case minus = "minus"
    case moon = "moon"
    case nosign = "nosign"
    case number = "number"
    case person2BadgeGearshapeFill = "person.2.badge.gearshape.fill"
    case personFill = "person.fill"
    case playCircle = "play.circle"
    case playCircleFill = "play.circle.fill"
    case questionmarkCircle = "questionmark.circle"
    case rectanglePortraitAndArrowRight = "rectangle.portrait.and.arrow.right"
    case squareStack3dUp = "square.stack.3d.up"
    case sunMax = "sun.max"
    case textDocument = "text.document"
    case trash = "trash"
    case tray = "tray"
    case wifiSlash = "wifi.slash"
    case xmarkCircleFill = "xmark.circle.fill"
}

extension UIImage {
    convenience init?(symbol: AppSymbol, withConfiguration configuration: UIImage.Configuration? = nil) {
        self.init(systemName: symbol.rawValue, withConfiguration: configuration)
    }
}

extension Image {
    init(symbol: AppSymbol) { self.init(systemName: symbol.rawValue) }
}

extension Label where Title == Text, Icon == Image {
    init(_ title: String, symbol: AppSymbol) {
        self.init { Text(title) } icon: { Image(symbol: symbol) }
    }
}

@MainActor
struct AppImages {
    static let arrowDown = UIImage(symbol: .arrowDown)?.withRenderingMode(.alwaysTemplate)
    static let arrowUp = UIImage(symbol: .arrowUp)?.withRenderingMode(.alwaysTemplate)
    static let chevronDown2 = UIImage(symbol: .chevronDown2)?.withRenderingMode(.alwaysTemplate)
    static let chevronLeft = UIImage(symbol: .chevronLeft)?.withRenderingMode(.alwaysTemplate)
    static let chevronRight = UIImage(symbol: .chevronRight)?.withRenderingMode(.alwaysTemplate)
    static let chevronUp2 = UIImage(symbol: .chevronUp2)?.withRenderingMode(.alwaysTemplate)
    static let circle = UIImage(symbol: .circle)?.withRenderingMode(.alwaysTemplate)
    static let desktopcomputer = UIImage(symbol: .desktopcomputer)?.withRenderingMode(.alwaysTemplate)
    static let exclamationmarkCircle = UIImage(symbol: .exclamationmarkCircle)?
        .withRenderingMode(.alwaysTemplate)
    static let externaldriveConnectedToLineBelowFill =
        UIImage(symbol: .externaldriveConnectedToLineBelowFill)?.withRenderingMode(.alwaysTemplate)
    static let folder = UIImage(symbol: .folder)?.withRenderingMode(.alwaysTemplate)
    static let gearshape2Fill = UIImage(symbol: .gearshape2Fill)?.withRenderingMode(.alwaysTemplate)
    static let gearshapeFill = UIImage(symbol: .gearshapeFill)?.withRenderingMode(.alwaysTemplate)
    static let handRaised = UIImage(symbol: .handRaised)?.withRenderingMode(.alwaysTemplate)
    static let logo = UIImage(named: "FullLogo")
    static let minus = UIImage(symbol: .minus)?.withRenderingMode(.alwaysTemplate)
    static let nosign = UIImage(symbol: .nosign)?.withRenderingMode(.alwaysTemplate)
    static let person2BadgeGearshapeFill = UIImage(symbol: .person2BadgeGearshapeFill)?
        .withRenderingMode(.alwaysTemplate)
    static let trash = UIImage(symbol: .trash)?.withRenderingMode(.alwaysTemplate)
}

extension View {
    @ViewBuilder
    func identified(by identifier: AccessibilityID?) -> some View {
        if let identifier { accessibilityIdentifier(identifier.identifier) }
        else { self }
    }
}
