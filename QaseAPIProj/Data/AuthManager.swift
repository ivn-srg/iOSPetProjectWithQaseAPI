import Foundation
import Security

enum AuthOperationError: Error { case cacheCleanupAfterLogout }

enum KeychainError: Error { case noToken, unexpectedTokenData, unhandledError(status: OSStatus) }

struct AuthCredential: Codable, Equatable, Sendable {
    let token: String
    let ownerID: String
    static func decode(_ data: Data) -> AuthCredential? {
        if let record = try? JSONDecoder().decode(Self.self, from: data) { return record }
        guard let token = String(data: data, encoding: .utf8), !token.isEmpty else { return nil }
        return AuthCredential(token: token, ownerID: UUID().uuidString)
    }
}

protocol AuthCredentialStorage {
    func getCredential() -> AuthCredential?
    func saveCredential(_ record: AuthCredential) throws
    func deleteToken() throws
}

struct ValidatedTokenCandidate: Sendable {
    fileprivate let credential: AuthCredential
    fileprivate let originalCredential: AuthCredential
    fileprivate let sessionStamp: SessionStamp
    fileprivate let usesDemo: Bool
    fileprivate let isSameToken: Bool
    fileprivate let managerID: UUID
    var requiresSessionChange: Bool { !isSameToken }
}

struct TokenReplacementResult: Sendable {
    let didChange: Bool
    let cacheCleanupFailed: Bool
}

@MainActor
struct AuthReplacementDependencies {
    let session: SessionContext
    let authenticate: @MainActor (String, Bool) async throws -> Bool
    let clearCache: @MainActor () throws -> Void
    let configureDemoMode: @MainActor (Bool) -> Void
    let notifyAuthChanged: @MainActor (Bool) -> Void

}

@MainActor
protocol AuthServicing: AnyObject {
    var isDemoMode: Bool { get }
    func isUserLoggedIn() -> Bool
    func loggedIn(token: String?) async throws
    func logout() async throws
    func validateReplacementToken(_ token: String) async throws -> ValidatedTokenCandidate
    func commitReplacementToken(_ candidate: ValidatedTokenCandidate) throws -> TokenReplacementResult
}

@MainActor
final class AuthManager: AuthServicing {
    private let userDefaults: UserDefaults
    private let authStatusKey = "isUserLoggedIn"
    private let credentialStore: AuthCredentialStorage
    private let replacementDependencies: AuthReplacementDependencies
    private let managerID = UUID()
    private let usesTestTokenStore: Bool
    private let isProtectedDataAvailable: @MainActor () -> Bool

    init(
        userDefaults: UserDefaults,
        credentialStore: AuthCredentialStorage,
        replacementDependencies: AuthReplacementDependencies,
        usesTestTokenStore: Bool = false,
        isProtectedDataAvailable: @escaping @MainActor () -> Bool = { true }
    ) {
        self.userDefaults = userDefaults
        self.credentialStore = credentialStore
        self.replacementDependencies = replacementDependencies
        self.usesTestTokenStore = usesTestTokenStore
        self.isProtectedDataAvailable = isProtectedDataAvailable
    }

    @MainActor
    var isDemoMode: Bool {
        guard let credential = currentCredential() else { return false }
        return usesTestTokenStore || credential.token == "QASE_DEMO"
    }

    @MainActor
    func validateReplacementToken(_ token: String) async throws -> ValidatedTokenCandidate {
        try Task.checkCancellation()
        let token = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else { throw API.NetError.invalidCredantials }
        let dependencies = replacementDependencies
        let stamp = dependencies.session.capture()
        guard let originalCredential = currentCredential(),
              stamp.ownerID == originalCredential.ownerID,
              userDefaults.bool(forKey: authStatusKey) else { throw CancellationError() }
        let usesDemo = usesTestTokenStore || token == "QASE_DEMO"
        let valid = try await dependencies.authenticate(token, usesDemo)
        try Task.checkCancellation()
        guard dependencies.session.capture() == stamp,
              currentCredential() == originalCredential,
              userDefaults.bool(forKey: authStatusKey) else { throw CancellationError() }
        guard valid else { throw API.NetError.invalidCredantials }
        let isSameToken = token == originalCredential.token
        return ValidatedTokenCandidate(
            credential: isSameToken ? originalCredential : AuthCredential(
                token: token,
                ownerID: UUID().uuidString
            ),
            originalCredential: originalCredential, sessionStamp: stamp, usesDemo: usesDemo,
            isSameToken: isSameToken, managerID: managerID
        )
    }

    @MainActor
    func commitReplacementToken(_ candidate: ValidatedTokenCandidate) throws -> TokenReplacementResult {
        try Task.checkCancellation()
        let dependencies = replacementDependencies
        guard candidate.managerID == managerID,
              dependencies.session.capture() == candidate.sessionStamp,
              currentCredential() == candidate.originalCredential,
              userDefaults.bool(forKey: authStatusKey) else { throw CancellationError() }
        guard !candidate.isSameToken else {
            return TokenReplacementResult(didChange: false, cacheCleanupFailed: false)
        }

        // Токен и владелец сохраняются вместе до изменения активной сессии и её кеша.
        try saveCredential(candidate.credential)
        dependencies.session.invalidate()
        clearSelectedProjects()
        var cacheCleanupFailed = false
        do { try dependencies.clearCache() } catch { cacheCleanupFailed = true }
        dependencies.configureDemoMode(candidate.usesDemo)
        dependencies.session.activate(ownerID: candidate.credential.ownerID)
        userDefaults.set(true, forKey: authStatusKey)
        dependencies.notifyAuthChanged(cacheCleanupFailed)
        return TokenReplacementResult(didChange: true, cacheCleanupFailed: cacheCleanupFailed)
    }

    /// Первый шаг сборки содержимого: удаляет токен прежней установки и восстанавливает сессию.
    /// Флаг входа ставится после сохранения токена и удаляется вместе с приложением, а Keychain — нет:
    /// токен без флага остался от прежней установки или прерванного входа.
    @MainActor
    func restoreSessionIfNeeded() {
        guard let credential = currentCredential() else { return }
        guard userDefaults.bool(forKey: authStatusKey) else {
            // При заблокированном устройстве ничего не удаляем: необратимо, повтор при следующем старте.
            if isProtectedDataAvailable() { try? deleteCredential() }
            return
        }
        guard replacementDependencies.session.ownerID == nil else { return }
        let usesDemo = usesTestTokenStore || credential.token == "QASE_DEMO"
        replacementDependencies.configureDemoMode(usesDemo)
        replacementDependencies.session.activate(ownerID: credential.ownerID)
    }

    @MainActor
    func isUserLoggedIn() -> Bool {
        currentCredential() != nil && userDefaults.bool(forKey: authStatusKey)
    }

    func getAuthToken() -> String? { currentCredential()?.token }

    private func currentCredential() -> AuthCredential? {
        credentialStore.getCredential()
    }

    @MainActor
    func loggedIn(token: String?) async throws {
        guard let token else { try await logout()
            return }
        let dependencies = replacementDependencies
        let startingStamp = dependencies.session.capture()
        let usesDemo = usesTestTokenStore || token == "QASE_DEMO"
        guard try await dependencies.authenticate(token, usesDemo)
        else { throw API.NetError.invalidCredantials }
        try Task.checkCancellation()
        guard dependencies.session.capture() == startingStamp else { return }
        let record = AuthCredential(token: token, ownerID: UUID().uuidString)
        try saveCredential(record)
        dependencies.session.invalidate()
        clearSelectedProjects()
        var cacheCleanupFailed = false
        do { try dependencies.clearCache() } catch { cacheCleanupFailed = true }
        dependencies.configureDemoMode(usesDemo)
        dependencies.session.activate(ownerID: record.ownerID)
        userDefaults.set(true, forKey: authStatusKey)
        dependencies.notifyAuthChanged(cacheCleanupFailed)
    }

    @MainActor
    func logout() async throws {
        try deleteCredential()
        let dependencies = replacementDependencies
        dependencies.session.invalidate()
        clearSelectedProjects()
        var cacheCleanupFailed = false
        do { try dependencies.clearCache() } catch { cacheCleanupFailed = true }
        userDefaults.set(false, forKey: authStatusKey)
        dependencies.notifyAuthChanged(false)
        if cacheCleanupFailed { throw AuthOperationError.cacheCleanupAfterLogout }
    }

    private func clearSelectedProjects() {
        for key in userDefaults.dictionaryRepresentation().keys where key.hasPrefix("selectedProject.") {
            userDefaults.removeObject(forKey: key)
        }
    }

    private func saveCredential(_ record: AuthCredential) throws {
        try credentialStore.saveCredential(record)
    }

    private func deleteCredential() throws {
        try credentialStore.deleteToken()
    }
}

final class KeychainService: AuthCredentialStorage {
    static let defaultKey = "authToken"
    /// Токен доступен только на этом устройстве и только после разблокировки: не уходит в бэкап.
    static let accessibility = kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String

    private let key: String
    private let updateAccessibility: (CFDictionary, CFDictionary) -> OSStatus
    private let lock = NSLock()
    /// Поиск без `kSecAttrAccessible`: иначе элементы прежних версий (класс `WhenUnlocked`) не найдутся.
    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrLabel as String: key
        ]
    }

    /// `updateAccessibility` — для тестов сбоя перевода класса доступности.
    init(
        key: String = KeychainService.defaultKey,
        updateAccessibility: @escaping (CFDictionary, CFDictionary) -> OSStatus = SecItemUpdate
    ) {
        self.key = key
        self.updateAccessibility = updateAccessibility
    }

    func saveCredential(_ record: AuthCredential) throws {
        lock.lock()
        defer { lock.unlock() }
        try saveUnlocked(record)
    }

    private func saveUnlocked(_ record: AuthCredential) throws {
        let data = try JSONEncoder().encode(record)
        // SecItemUpdate replaces token, owner and accessibility together; never delete before saving.
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: Self.accessibility
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            let insertion = query.merging(attributes) { _, new in new }
            let result = SecItemAdd(insertion as CFDictionary, nil)
            guard result == errSecSuccess else { throw KeychainError.unhandledError(status: result) }
        } else if status != errSecSuccess { throw KeychainError.unhandledError(status: status) }
    }

    func getCredential() -> AuthCredential? {
        lock.lock()
        defer { lock.unlock() }
        var read = query
        read[kSecReturnData as String] = true
        read[kSecReturnAttributes as String] = true
        var item: CFTypeRef?
        guard SecItemCopyMatching(read as CFDictionary, &item) == errSecSuccess,
              let attributes = item as? [String: Any],
              let data = attributes[kSecValueData as String] as? Data,
              let record = AuthCredential.decode(data) else { return nil }
        if (try? JSONDecoder().decode(AuthCredential.self, from: data)) == nil {
            // Upgrade legacy UTF8 records once so the account marker persists across launches;
            // the same update moves the item to the device-only accessibility class.
            guard (try? saveUnlocked(record)) != nil else { return nil }
        } else if attributes[kSecAttrAccessible as String] as? String != Self.accessibility {
            // Элемент прежней версии: перевод класса на месте.
            // Сбой не скрывает токен — повтор при следующем чтении.
            let update = [kSecAttrAccessible as String: Self.accessibility]
            _ = updateAccessibility(query as CFDictionary, update as CFDictionary)
        }
        return record
    }

    func deleteToken() throws {
        lock.lock()
        defer { lock.unlock() }
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound
        else { throw KeychainError.unhandledError(status: status) }
    }
}

final class MemoryCredentialStorage: AuthCredentialStorage {
    private let lock = NSLock()
    private var record: AuthCredential?

    func getCredential() -> AuthCredential? {
        lock.lock()
        defer { lock.unlock() }
        return record
    }

    func saveCredential(_ record: AuthCredential) throws {
        lock.lock()
        defer { lock.unlock() }
        self.record = record
    }

    func deleteToken() throws {
        lock.lock()
        defer { lock.unlock() }
        record = nil
    }
}
