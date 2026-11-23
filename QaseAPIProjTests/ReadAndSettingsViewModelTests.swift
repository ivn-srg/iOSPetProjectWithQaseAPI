import Foundation
@testable import QaseAPIProj
import Testing

/// Экран детали чтения (`ReadDetailViewModel`) и настройки кеша (`SettingsViewModel`).
@Suite(.timeLimit(.minutes(1))) @MainActor
struct ReadAndSettingsViewModelTests {
    // MARK: - ReadDetailViewModel

    // Мутация: не записывать результат `fetch` в `item` или не гасить `loading`.
    @Test func successfulLoadPublishesFetchedItem() async {
        let model = Self.detail(cached: nil) { "fresh" }
        await model.load()
        #expect(model.item == "fresh")
        #expect(model.errorMessage == nil)
        #expect(!model.loading)
        #expect(!model.usingCache)
    }

    // Мутация: убрать `if item == nil { item = cached() }` — до ответа экран пустой.
    @Test func cachedItemIsShownWhileRequestIsPending() async {
        let gate = DetailGate()
        let model = Self.detail(cached: "cached") { try await gate.fetch() }
        let load = Task { await model.load() }
        await waitForCondition { gate.isWaiting }
        #expect(model.item == "cached")
        #expect(model.loading)
        #expect(!model.usingCache)
        gate.finish(.success("fresh"))
        await load.value
        #expect(model.item == "fresh")
        #expect(!model.loading)
    }

    // Мутация: `usingCache = false` в `catch` либо сброс `item` при ошибке.
    @Test func failureWithShownItemKeepsItAndMarksCacheUse() async {
        let model = Self.detail(cached: "cached") { throw CocoaError(.fileReadUnknown) }
        await model.load()
        #expect(model.item == "cached")
        #expect(model.usingCache)
        #expect(model.errorMessage == "Could not load run")
        #expect(!model.loading)
    }

    // Мутация: `usingCache = true` без проверки `item != nil`.
    @Test func failureWithoutItemDoesNotClaimCacheUse() async {
        let model = Self.detail(cached: nil) { throw API.NetError.noInternetConnection }
        await model.load()
        #expect(model.item == nil)
        #expect(!model.usingCache)
        #expect(model.errorMessage == "Could not connect. Check your internet connection and try again."
            .localized)
    }

    // Мутация: не сбрасывать `errorMessage` или `usingCache` после успешной повторной загрузки.
    @Test func successAfterFailureClearsErrorAndCacheMarker() async {
        let outcomes = DetailOutcomes([.failure(CocoaError(.fileReadUnknown)), .success("fresh")])
        let model = Self.detail(cached: "cached") { try outcomes.next() }
        await model.load()
        #expect(model.usingCache)
        #expect(model.errorMessage != nil)
        await model.load()
        #expect(model.item == "fresh")
        #expect(model.errorMessage == nil)
        #expect(!model.usingCache)
    }

    // Мутация: убрать `session.isCurrent(stamp)` в ветке успеха — поздний ответ попадает на экран.
    @Test func lateSuccessAfterSessionChangeIsNotPublished() async {
        let session = SessionContext(ownerID: "A")
        let gate = DetailGate()
        let model = Self.detail(session: session, cached: nil) { try await gate.fetch() }
        let load = Task { await model.load() }
        await waitForCondition { gate.isWaiting }
        session.activate(ownerID: "B")
        gate.finish(.success("late"))
        await load.value
        #expect(model.item == nil)
        #expect(!model.usingCache)
        #expect(model.errorMessage == nil)
        #expect(!model.loading)
    }

    // Мутация: убрать `session.isCurrent(stamp)` в `catch` — ошибка старой сессии показывается новой.
    @Test func lateFailureAfterSessionChangeIsNotPublished() async {
        let session = SessionContext(ownerID: "A")
        let gate = DetailGate()
        let model = Self.detail(session: session, cached: "cached") { try await gate.fetch() }
        let load = Task { await model.load() }
        await waitForCondition { gate.isWaiting }
        session.activate(ownerID: "B")
        gate.finish(.failure(CocoaError(.fileReadUnknown)))
        await load.value
        #expect(model.errorMessage == nil)
        #expect(!model.usingCache)
        #expect(!model.loading)
    }

    // Мутация: убрать `session.isCurrent(stamp)` из первого `guard` — запрос уходит после выхода.
    @Test func loadOnInvalidatedSessionSendsNothing() async {
        let session = SessionContext(ownerID: "A")
        let outcomes = DetailOutcomes([.success("unexpected")])
        let model = Self.detail(session: session, cached: "cached") { try outcomes.next() }
        session.invalidate()
        await model.load()
        #expect(outcomes.calls == 0)
        #expect(model.item == nil)
        #expect(!model.loading)
    }

    // Мутация: убрать `!loading` из первого `guard` — второй вызов шлёт второй запрос.
    @Test func repeatedLoadWhilePendingSendsOnlyOneRequest() async {
        let gate = DetailGate()
        let model = Self.detail(cached: nil) { try await gate.fetch() }
        let first = Task { await model.load() }
        await waitForCondition { gate.isWaiting }
        let finished = Counter()
        let second = Task {
            await model.load()
            finished.value += 1
        }
        await waitForCondition { finished.value == 1 || gate.calls == 2 }
        #expect(gate.calls == 1)
        gate.finish(.success("fresh"))
        await first.value
        await second.value
        #expect(model.item == "fresh")
    }

    // MARK: - SettingsViewModel

    // Мутация: не присваивать результат `hasDownloadedData` в `hasCachedData`.
    @Test(arguments: [true, false])
    func refreshCacheReflectsDownloadedData(hasData: Bool) {
        let cache = SettingsCacheFake(hasData: .success(hasData))
        let model = Self.settings(cache: cache)
        model.refreshCache()
        #expect(model.hasCachedData == hasData)
        #expect(model.cacheError == nil)
        #expect(model.cacheNotice == nil)
    }

    // Мутация: подменить текст ошибки чтения или не записывать его в `cacheError`.
    @Test func refreshCacheReportsReadFailure() {
        let cache = SettingsCacheFake(hasData: .failure(CocoaError(.fileReadUnknown)))
        let model = Self.settings(cache: cache)
        model.refreshCache()
        #expect(model.cacheError == "Could not read cached data".localized)
        #expect(model.cacheNotice == nil)
    }

    // Мутация: убрать `cacheError = nil` / `cacheNotice = nil` в начале `refreshCache`.
    @Test func refreshCacheClearsPreviousErrorAndNotice() {
        let cache = SettingsCacheFake(hasData: .failure(CocoaError(.fileReadUnknown)))
        let model = Self.settings(cache: cache)
        model.refreshCache()
        #expect(model.cacheError != nil)
        cache.hasData = .success(true)
        model.refreshCache()
        #expect(model.cacheError == nil)
        #expect(model.hasCachedData)
        model.clearCache()
        #expect(model.cacheNotice == "Cache cleared".localized)
        model.refreshCache()
        #expect(model.cacheNotice == nil)
    }

    // Мутация: не вызывать `refreshCache` после очистки (флаг устаревает) или не ставить уведомление.
    @Test func clearCacheSucceedsAndRefreshesFlag() {
        let cache = SettingsCacheFake(hasData: .success(true))
        let model = Self.settings(cache: cache)
        model.refreshCache()
        #expect(model.hasCachedData)
        model.clearCache()
        #expect(cache.clearCalls == 1)
        #expect(!model.hasCachedData)
        #expect(model.cacheNotice == "Cache cleared".localized)
        #expect(model.cacheError == nil)
    }

    // Мутация: показывать «Cache cleared» при ошибке очистки или не показывать причину.
    @Test func clearCacheFailureReportsErrorWithoutNotice() {
        let cache = SettingsCacheFake(hasData: .success(true))
        cache.clearError = CocoaError(.fileWriteUnknown)
        let model = Self.settings(cache: cache)
        model.refreshCache()
        model.clearCache()
        #expect(model.cacheError == "Could not clear cached data".localized)
        #expect(model.cacheNotice == nil)
        #expect(model.hasCachedData)
    }

    // Мутация: ставить уведомление без проверки `cacheError == nil` после повторного чтения.
    @Test func clearCacheDoesNotClaimSuccessWhenRereadFails() {
        let cache = SettingsCacheFake(hasData: .success(true))
        cache.hasDataAfterClear = .failure(CocoaError(.fileReadUnknown))
        let model = Self.settings(cache: cache)
        model.clearCache()
        #expect(cache.clearCalls == 1)
        #expect(model.cacheError == "Could not read cached data".localized)
        #expect(model.cacheNotice == nil)
    }

    // Мутация: захватывать `SessionStamp` один раз в `init` вместо каждого вызова.
    @Test func cacheCallsUseCurrentSessionStamp() {
        let session = SessionContext(ownerID: "A")
        let cache = SettingsCacheFake(hasData: .success(false))
        let model = Self.settings(cache: cache, session: session)
        session.activate(ownerID: "B")
        model.refreshCache()
        model.clearCache()
        let expected = session.capture()
        #expect(!cache.stamps.isEmpty)
        #expect(cache.stamps.allSatisfy { $0 == expected })
    }

    // Мутация: вернуть общий флаг вместо данных владельца или не передавать сессию в кеш.
    @Test func realCacheReportsAndClearsOwnerDataAndFailsAfterSessionInvalidation() throws {
        let session = SessionContext(ownerID: "owner")
        let cache = TestDependencies.cache(session: session)
        let project = try JSONDecoder().decode(
            Project.self,
            from: Data(#"{"title":"A","code":"A"}"#.utf8)
        )
        #expect(cache.saveProjects([project], stamp: session.capture()))
        let model = Self.settings(cache: cache, session: session)

        model.refreshCache()
        #expect(model.hasCachedData)
        model.clearCache()
        #expect(!model.hasCachedData)
        #expect(model.cacheNotice == "Cache cleared".localized)

        session.invalidate()
        model.refreshCache()
        #expect(model.cacheError == "Could not read cached data".localized)
        model.clearCache()
        #expect(model.cacheError == "Could not clear cached data".localized)
        #expect(model.cacheNotice == nil)
    }

    // MARK: - Helpers

    private static func detail(
        session: SessionContext? = nil,
        cached: String?,
        fetch: @escaping () async throws -> String
    ) -> ReadDetailViewModel<String> {
        // Значение по умолчанию создаётся здесь: аргументы по умолчанию вычисляются вне MainActor.
        ReadDetailViewModel<String>(
            session: session ?? SessionContext(ownerID: "owner"),
            cached: { cached },
            failureMessage: "Could not load run",
            fetch: fetch
        )
    }

    private static func settings(
        cache: CacheMaintaining,
        session: SessionContext? = nil
    ) -> SettingsViewModel {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        return SettingsViewModel(
            preferences: AppSettingsStore(defaults: defaults),
            auth: SettingsAuthStub(),
            cache: cache,
            session: session ?? SessionContext(ownerID: "owner"),
            bundle: .main
        )
    }
}

/// Запрос, который завершается только вызовом `finish`; несколько ожидающих получают один ответ.
@MainActor
private final class DetailGate {
    private var waiters: [CheckedContinuation<Result<String, Error>, Never>] = []
    private(set) var calls = 0
    var isWaiting: Bool { !waiters.isEmpty }

    func fetch() async throws -> String {
        calls += 1
        let result = await withCheckedContinuation { waiters.append($0) }
        return try result.get()
    }

    func finish(_ result: Result<String, Error>) {
        let pending = waiters
        waiters = []
        for waiter in pending { waiter.resume(returning: result) }
    }
}

/// Готовые ответы по порядку вызовов.
@MainActor
private final class DetailOutcomes {
    private var outcomes: [Result<String, Error>]
    private(set) var calls = 0

    init(_ outcomes: [Result<String, Error>]) { self.outcomes = outcomes }

    func next() throws -> String {
        calls += 1
        return try outcomes.removeFirst().get()
    }
}

@MainActor
private final class Counter { var value = 0 }

/// Кеш с настраиваемыми результатами; после `clearDownloadedData` чтение отдаёт `hasDataAfterClear`
/// (по умолчанию «данных нет»).
@MainActor
private final class SettingsCacheFake: CacheMaintaining {
    var hasData: Result<Bool, Error>
    var hasDataAfterClear: Result<Bool, Error> = .success(false)
    var clearError: Error?
    private(set) var clearCalls = 0
    private(set) var stamps: [SessionStamp] = []

    init(hasData: Result<Bool, Error>) { self.hasData = hasData }

    func clearAll() throws {}
    func useDemoStore(_ enabled: Bool) {}

    func hasDownloadedData(stamp: SessionStamp) throws -> Bool {
        stamps.append(stamp)
        return try hasData.get()
    }

    func clearDownloadedData(stamp: SessionStamp) throws {
        stamps.append(stamp)
        if let clearError { throw clearError }
        clearCalls += 1
        hasData = hasDataAfterClear
    }
}

private enum SettingsAuthStubError: Error { case unexpectedCall }

@MainActor
private final class SettingsAuthStub: AuthServicing {
    var isDemoMode: Bool { false }
    func isUserLoggedIn() -> Bool { true }
    func loggedIn(token: String?) async throws { throw SettingsAuthStubError.unexpectedCall }
    func logout() async throws { throw SettingsAuthStubError.unexpectedCall }
    func validateReplacementToken(_ token: String) async throws -> ValidatedTokenCandidate {
        throw SettingsAuthStubError.unexpectedCall
    }

    func commitReplacementToken(_ candidate: ValidatedTokenCandidate) throws -> TokenReplacementResult {
        throw SettingsAuthStubError.unexpectedCall
    }
}
