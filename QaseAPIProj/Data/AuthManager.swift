import Foundation
import Security

enum AuthState: String { case loggedIn = "loggedIn", loggedOutb = "loggedOut" }
enum KeychainError: Error { case noToken, unexpectedTokenData, unhandledError(status: OSStatus) }

struct AuthCredential: Codable, Equatable {
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

struct ValidatedTokenCandidate {
    fileprivate let credential: AuthCredential
    fileprivate let originalCredential: AuthCredential
    fileprivate let sessionStamp: SessionStamp
    fileprivate let usesDemo: Bool
    fileprivate let isSameToken: Bool
    fileprivate let managerID: UUID
    var requiresSessionChange: Bool { !isSameToken }
}

struct TokenReplacementResult {
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

    static var live: Self {
        Self(session: .shared, authenticate: { token, usesDemo in
            let network: NetworkManager = usesDemo ? APIMockManager.shared : APIManager.shared
            return try await network.auth(by: token)
        }, clearCache: {
            try RealmManager.shared.clearAll()
        }, configureDemoMode: { usesDemo in
            ApiServiceConfiguration.shared.setMockingServiceEnabled(usesDemo)
            RealmManager.shared.useDemoStore(usesDemo)
        }, notifyAuthChanged: { cacheCleanupFailed in
            NotificationCenter.default.post(
                name: .didChangeAuthStatus,
                object: nil,
                userInfo: ["cacheCleanupFailed": cacheCleanupFailed]
            )
        })
    }
}

final class AuthManager {
    static let shared = AuthManager()
    private let userDefaults: UserDefaults
    private let authStatusKey = "isUserLoggedIn"
    private let keychain = KeychainService.shared
    private let credentialStore: AuthCredentialStorage?
    private let replacementDependencies: AuthReplacementDependencies?
    private let managerID = UUID()
    private let testLock = NSLock()
    private var testCredential: AuthCredential?
    private var usesTestTokenStore: Bool {
        #if DEBUG
            CommandLine.arguments.contains("UITests")
        #else
            false
        #endif
    }

    init(
        userDefaults: UserDefaults = .standard,
        credentialStore: AuthCredentialStorage? = nil,
        replacementDependencies: AuthReplacementDependencies? = nil
    ) {
        self.userDefaults = userDefaults
        self.credentialStore = credentialStore
        self.replacementDependencies = replacementDependencies
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
        let dependencies = replacementDependencies ?? .live
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
        let dependencies = replacementDependencies ?? .live
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

    @MainActor
    func isUserLoggedIn() -> Bool {
        let credential = currentCredential()
        if let credential, SessionContext.shared.ownerID == nil {
            let usesDemo = usesTestTokenStore || credential.token == "QASE_DEMO"
            ApiServiceConfiguration.shared.setMockingServiceEnabled(usesDemo)
            if usesDemo { RealmManager.shared.useDemoStore(true) }
            SessionContext.shared.activate(ownerID: credential.ownerID)
        }
        return credential != nil && userDefaults.bool(forKey: authStatusKey)
    }

    // Used by the request transport from arbitrary executors. No Realm or UI access here.
    func getAuthToken() -> String? { currentCredential()?.token }

    private func currentCredential() -> AuthCredential? {
        if let credentialStore { return credentialStore.getCredential() }
        if usesTestTokenStore {
            testLock.lock()
            defer { testLock.unlock() }
            return testCredential
        }
        return keychain.getCredential()
    }

    @MainActor
    func loggedIn(token: String?) async throws {
        guard let token else { try await logout()
            return }
        let startingStamp = SessionContext.shared.capture()
        let usesDemo = usesTestTokenStore || token == "QASE_DEMO"
        let network: NetworkManager = usesDemo ? APIMockManager.shared : APIManager.shared
        let valid = try await network.auth(by: token)
        guard valid else { throw API.NetError.invalidCredantials }
        // A concurrent logout/login supersedes this candidate.
        guard SessionContext.shared.capture() == startingStamp else { return }
        SessionContext.shared.invalidate()
        clearSelectedProjects()
        try RealmManager.shared.clearAll()
        let record = AuthCredential(token: token, ownerID: UUID().uuidString)
        try saveCredential(record)
        ApiServiceConfiguration.shared.setMockingServiceEnabled(usesDemo)
        RealmManager.shared.useDemoStore(usesDemo)
        SessionContext.shared.activate(ownerID: record.ownerID)
        userDefaults.set(true, forKey: authStatusKey)
        NotificationCenter.default.post(name: .didChangeAuthStatus, object: nil)
    }

    @MainActor
    func logout() async throws {
        SessionContext.shared.invalidate()
        clearSelectedProjects()
        var cleanupError: Error?
        do { try RealmManager.shared.clearAll() } catch { cleanupError = error }
        try deleteCredential()
        userDefaults.set(false, forKey: authStatusKey)
        NotificationCenter.default.post(name: .didChangeAuthStatus, object: nil)
        if let cleanupError { throw cleanupError }
    }

    private func clearSelectedProjects() {
        for key in userDefaults.dictionaryRepresentation().keys where key.hasPrefix("selectedProject.") {
            userDefaults.removeObject(forKey: key)
        }
    }

    private func saveCredential(_ record: AuthCredential) throws {
        if let credentialStore { try credentialStore.saveCredential(record)
            return }
        if usesTestTokenStore {
            testLock.lock()
            defer { testLock.unlock() }
            testCredential = record
        } else { try keychain.saveCredential(record) }
    }

    private func deleteCredential() throws {
        if let credentialStore { try credentialStore.deleteToken()
            return }
        if usesTestTokenStore {
            testLock.lock()
            defer { testLock.unlock() }
            testCredential = nil
        } else { try keychain.deleteToken() }
    }
}

private final class KeychainService: AuthCredentialStorage {
    static let shared = KeychainService()
    private let key = "authToken"
    private let lock = NSLock()
    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrLabel as String: key
        ]
    }

    func saveCredential(_ record: AuthCredential) throws {
        lock.lock()
        defer { lock.unlock() }
        try saveUnlocked(record)
    }

    private func saveUnlocked(_ record: AuthCredential) throws {
        let data = try JSONEncoder().encode(record)
        // SecItemUpdate replaces token and owner together; never delete before saving.
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var insertion = query
            insertion[kSecValueData as String] = data
            let result = SecItemAdd(insertion as CFDictionary, nil)
            guard result == errSecSuccess else { throw KeychainError.unhandledError(status: result) }
        } else if status != errSecSuccess { throw KeychainError.unhandledError(status: status) }
    }

    func getCredential() -> AuthCredential? {
        lock.lock()
        defer { lock.unlock() }
        var read = query
        read[kSecReturnData as String] = true
        var item: CFTypeRef?
        guard SecItemCopyMatching(read as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data, let record = AuthCredential.decode(data) else { return nil }
        if (try? JSONDecoder().decode(AuthCredential.self, from: data)) == nil {
            // Upgrade legacy UTF8 records once so the account marker persists across launches.
            guard (try? saveUnlocked(record)) != nil else { return nil }
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
