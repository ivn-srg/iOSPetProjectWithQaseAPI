// AppSettingsStore.swift
// QaseAPIProj
// Сохраняемые настройки оформления приложения.

import Combine
import Foundation
import UIKit

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "Follow system".localized
        case .light: return "Light".localized
        case .dark: return "Dark".localized
        }
    }

    var symbol: AppSymbol {
        switch self {
        case .system: return .circleLefthalfFilled
        case .light: return .sunMax
        case .dark: return .moon
        }
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
final class AppSettingsStore: ObservableObject {
    static let appearanceKey = "qase.app.appearance"
    private let defaults: UserDefaults

    @Published var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Self.appearanceKey) }
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        appearance = defaults.string(forKey: Self.appearanceKey)
            .flatMap(AppAppearance.init(rawValue:)) ?? .system
    }
}

extension AppAppearance {
    var accessibilityAppearance: AccessibilityID.Appearance {
        switch self {
        case .system: return .system
        case .light: return .light
        case .dark: return .dark
        }
    }
}
