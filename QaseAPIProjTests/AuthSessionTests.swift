import Foundation
@testable import QaseAPIProj
import Testing

/// Вход, выход и восстановление сессии `AuthManager` на фикстуре замены токена.
@Suite(.timeLimit(.minutes(1))) @MainActor
struct AuthSessionTests {
    // Ловит: выход не очищает выбор проекта (в т.ч. чужого владельца), чистит лишние ключи,
    // не инвалидирует сессию, не очищает кеш, не сбрасывает флаг или шлёт не то уведомление.
    @Test func logoutClearsSessionStateAndKeepsUnrelatedPreferences() async throws {
        let fixture = TokenReplacementFixture()
        try await fixture.auth.logout()
        #expect(fixture.defaults.string(forKey: "selectedProject.old-owner") == nil)
        #expect(fixture.defaults.string(forKey: "selectedProject.another-owner") == nil)
        #expect(fixture.defaults.string(forKey: "appearancePreference") == "dark")
        #expect(fixture.defaults.bool(forKey: "featureFlag"))
        #expect(!fixture.defaults.bool(forKey: "isUserLoggedIn"))
        #expect(!fixture.cachedOldData)
        #expect(fixture.session.ownerID == nil)
        #expect(fixture.storage.getCredential() == nil)
        #expect(fixture.storage.deleteCount == 1)
        #expect(!fixture.auth.isUserLoggedIn())
        #expect(fixture.events == ["clear", "notify"])
        #expect(fixture.notifications == [false])
        #expect(fixture.configuredModes.isEmpty)
    }

    // Ловит: сбой очистки кеша прерывает выход до сброса сессии или не сообщается вызывающему.
    @Test func logoutReportsCacheCleanupFailureAfterFinishingTheSignOut() async {
        let fixture = TokenReplacementFixture()
        fixture.failCacheCleanup = true
        do {
            try await fixture.auth.logout()
            Issue.record("A failed cache cleanup must be reported")
        } catch {
            #expect(error as? AuthOperationError == .cacheCleanupAfterLogout)
        }
        #expect(fixture.storage.getCredential() == nil)
        #expect(fixture.session.ownerID == nil)
        #expect(!fixture.defaults.bool(forKey: "isUserLoggedIn"))
        #expect(fixture.defaults.string(forKey: "selectedProject.old-owner") == nil)
        #expect(fixture.defaults.string(forKey: "appearancePreference") == "dark")
        #expect(fixture.notifications == [false])
    }

    // Ловит: вход не очищает выбор, не активирует новую сессию или владельца, не сохраняет
    // токен, передаёт неверный режим, не поднимает флаг входа.
    @Test func loggedInWithValidTokenReplacesSessionAndClearsSelection() async throws {
        let fixture = TokenReplacementFixture()
        fixture.defaults.set(false, forKey: "isUserLoggedIn")
        try await fixture.auth.loggedIn(token: "new-fixture")
        #expect(fixture.requests.map(\.token) == ["new-fixture"])
        #expect(fixture.requests.map(\.demo) == [false])
        #expect(fixture.storage.savedRecords.map(\.token) == ["new-fixture"])
        let record = try #require(fixture.storage.getCredential())
        #expect(record.token == "new-fixture")
        #expect(record.ownerID != "old-owner")
        #expect(fixture.session.ownerID == record.ownerID)
        #expect(fixture.session.capture() != fixture.originalStamp)
        #expect(fixture.defaults.string(forKey: "selectedProject.old-owner") == nil)
        #expect(fixture.defaults.string(forKey: "selectedProject.another-owner") == nil)
        #expect(fixture.defaults.string(forKey: "appearancePreference") == "dark")
        #expect(fixture.defaults.bool(forKey: "isUserLoggedIn"))
        #expect(!fixture.cachedOldData)
        #expect(fixture.events == ["clear", "configure", "notify"])
        #expect(fixture.configuredModes == [false])
        #expect(fixture.notifications == [false])
        #expect(fixture.auth.isUserLoggedIn())
    }

    // Ловит: демо-токен не включает демо-режим при входе (или включает его для обычного токена).
    @Test func loggedInWithDemoTokenSwitchesToDemoMode() async throws {
        let fixture = TokenReplacementFixture()
        try await fixture.auth.loggedIn(token: "QASE_DEMO")
        #expect(fixture.requests.map(\.token) == ["QASE_DEMO"])
        #expect(fixture.requests.map(\.demo) == [true])
        #expect(fixture.configuredModes == [true])
        #expect(fixture.storage.getCredential()?.token == "QASE_DEMO")
        #expect(fixture.auth.isDemoMode)
    }

    // Ловит: вход с `nil` не выполняет выход (или пытается проверять токен).
    @Test func loggedInWithNilTokenSignsOut() async throws {
        let fixture = TokenReplacementFixture()
        try await fixture.auth.loggedIn(token: nil)
        #expect(fixture.requests.isEmpty)
        #expect(fixture.storage.getCredential() == nil)
        #expect(fixture.storage.deleteCount == 1)
        #expect(fixture.storage.savedRecords.isEmpty)
        #expect(fixture.session.ownerID == nil)
        #expect(!fixture.defaults.bool(forKey: "isUserLoggedIn"))
        #expect(fixture.defaults.string(forKey: "selectedProject.old-owner") == nil)
        #expect(fixture.notifications == [false])
    }

    // Ловит: удаление проверки `capture() == startingStamp` после проверки токена: ответ
    // старой сессии сохраняет токен и перезаписывает уже новую сессию.
    @Test func sessionChangedDuringLoginSavesAndActivatesNothing() async throws {
        let fixture = TokenReplacementFixture()
        fixture.authenticate = { [unowned fixture] _, _ in
            fixture.session.activate(ownerID: "another-owner")
            return true
        }
        try await fixture.auth.loggedIn(token: "new-fixture")
        let changed = SessionStamp(ownerID: "another-owner", generation: fixture.originalStamp.generation + 1)
        fixture.expectPreserved(stamp: changed)
    }

    // Ловит: холодный запуск (сессия не активна, токен сохранён) не активирует сессию владельца
    // токена и не выбирает режим; повторный вызов активирует сессию заново.
    @Test(arguments: [("old-fixture", false), ("QASE_DEMO", true)])
    func coldCheckActivatesSessionAndModeOnce(token: String, demo: Bool) throws {
        let fixture = TokenReplacementFixture()
        try fixture.storage.saveCredential(AuthCredential(token: token, ownerID: "stored-owner"))
        fixture.session.invalidate()
        let invalidated = fixture.session.capture()
        #expect(fixture.auth.isUserLoggedIn())
        #expect(fixture.session.ownerID == "stored-owner")
        #expect(fixture.session.capture().generation == invalidated.generation + 1)
        #expect(fixture.configuredModes == [demo])
        #expect(fixture.auth.isUserLoggedIn())
        #expect(fixture.session.capture().generation == invalidated.generation + 1)
        #expect(fixture.configuredModes == [demo])
    }

    // Ловит: удаление условия `session.ownerID == nil` в `isUserLoggedIn()` (:142):
    // тёплая проверка повторно активирует сессию и обнуляет её штамп.
    @Test func warmCheckKeepsTheActiveSessionStamp() {
        let fixture = TokenReplacementFixture()
        #expect(fixture.auth.isUserLoggedIn())
        #expect(fixture.auth.isUserLoggedIn())
        #expect(fixture.session.capture() == fixture.originalStamp)
        #expect(fixture.configuredModes.isEmpty)
        #expect(fixture.events.isEmpty)
    }
}
