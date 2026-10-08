// AppSettingsTests.swift
// QaseAPIProjTests
// Проверки сохранения темы в изолированном хранилище.

import Foundation
import Testing
import UIKit
@testable import QaseAPIProj

@Suite @MainActor
struct AppSettingsTests {
    @Test func appearanceDefaultsToSystemAndPersistsChanges() throws {
        let name = "AppSettingsTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = AppSettingsStore(defaults: defaults)
        #expect(store.appearance == .system)
        #expect(store.appearance.interfaceStyle == .unspecified)
        store.appearance = .dark
        #expect(AppSettingsStore(defaults: defaults).appearance == .dark)
        #expect(store.appearance.interfaceStyle == .dark)
        store.appearance = .light
        #expect(AppSettingsStore(defaults: defaults).appearance == .light)
        store.appearance = .system
        #expect(AppSettingsStore(defaults: defaults).appearance == .system)
    }

    @Test func invalidStoredAppearanceFallsBackAndDoesNotTouchOtherPreferences() throws {
        let name = "AppSettingsTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set("unsupported", forKey: AppSettingsStore.appearanceKey)
        defaults.set("DEMO", forKey: "selectedProject.owner")
        defaults.set(true, forKey: "isUserLoggedIn")
        let store = AppSettingsStore(defaults: defaults)
        #expect(store.appearance == .system)
        store.appearance = .dark
        #expect(defaults.string(forKey: "selectedProject.owner") == "DEMO")
        #expect(defaults.bool(forKey: "isUserLoggedIn"))
    }
}
