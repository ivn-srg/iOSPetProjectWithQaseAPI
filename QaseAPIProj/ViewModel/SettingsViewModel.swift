// SettingsViewModel.swift
// QaseAPIProj
// Состояние настроек и формы замены API-токена.

import Combine
import Foundation

enum SettingsRoute { case appearance, language, token, cache, about, logout }

@MainActor
final class SettingsViewModel: ObservableObject {
    let preferences: AppSettingsStore
    let auth: AuthManager
    private let cache: RealmManager
    private let session: SessionContext
    private let bundle: Bundle
    @Published private(set) var languageName = ""
    @Published private(set) var hasCachedData = false
    @Published private(set) var cacheError: String?
    @Published private(set) var cacheNotice: String?

    init(
        preferences: AppSettingsStore,
        auth: AuthManager = .shared,
        cache: RealmManager = .shared,
        session: SessionContext = .shared,
        bundle: Bundle = .main
    ) {
        self.preferences = preferences
        self.auth = auth
        self.cache = cache
        self.session = session
        self.bundle = bundle
        refreshLanguage()
    }

    var accountSubtitle: String { (auth.isDemoMode ? "Demo mode" : "Signed in with API token").localized }
    var appName: String {
        bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Qase"
    }

    var version: String { bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    var buildNumber: String { bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—" }

    func refreshLanguage() {
        let code = bundle.preferredLocalizations.first ?? bundle.developmentLocalization ?? "en"
        languageName = (Locale.current.localizedString(forLanguageCode: code) ?? code).localizedCapitalized
    }

    func refreshCache() {
        cacheError = nil
        cacheNotice = nil
        do { hasCachedData = try cache.hasDownloadedData(stamp: session.capture()) }
        catch { cacheError = "Could not read cached data".localized }
    }

    func clearCache() {
        cacheError = nil
        cacheNotice = nil
        do {
            try cache.clearDownloadedData(stamp: session.capture())
            refreshCache()
            if cacheError == nil { cacheNotice = "Cache cleared".localized }
        } catch { cacheError = "Could not clear cached data".localized }
    }
}

@MainActor
final class TokenReplacementViewModel: ObservableObject {
    @Published var token = ""
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?
    var onClose: (() -> Void)?
    private let auth: AuthManager
    private let prepareForChange: @MainActor () async -> Bool
    private var task: Task<Void, Never>?

    init(auth: AuthManager, prepareForChange: @escaping @MainActor () async -> Bool) {
        self.auth = auth
        self.prepareForChange = prepareForChange
    }

    var canSave: Bool { !isSaving && !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    @discardableResult
    func save() -> Task<Void, Never>? {
        guard canSave else { return nil }
        let enteredToken = token
        isSaving = true
        errorMessage = nil
        task = Task { [weak self] in
            guard let self else { return }
            defer { self.isSaving = false }
            do {
                let candidate = try await self.auth.validateReplacementToken(enteredToken)
                try Task.checkCancellation()
                if candidate.requiresSessionChange {
                    guard await self.prepareForChange() else { return }
                }
                try Task.checkCancellation()
                _ = try self.auth.commitReplacementToken(candidate)
                self.token = ""
                self.onClose?()
            } catch is CancellationError {
                return
            } catch {
                self.errorMessage = Self.message(for: error)
            }
        }
        return task
    }

    private static func message(for error: Error) -> String {
        if error is KeychainError { return "Could not save API token. Try again.".localized }
        if let networkError = error as? API.NetError {
            switch networkError {
            case .invalidCredantials, .httpError(statusCode: 401, message: _, retryAfter: _):
                return "Could not update API token. Check the token and try again.".localized
            case .httpError(statusCode: 403, message: _, retryAfter: _):
                return "Could not verify access with this token".localized
            case .noInternetConnection:
                return "Could not verify API token. Check your internet connection and try again.".localized
            case .timeout:
                return "Token verification timed out. Try again.".localized
            default:
                break
            }
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "Could not verify API token. Check your internet connection and try again.".localized
            case .timedOut:
                return "Token verification timed out. Try again.".localized
            default:
                break
            }
        }
        return "Could not update API token. Try again.".localized
    }

    func stop() {
        task?.cancel()
        task = nil
        token = ""
    }

    func cancel() { stop()
        onClose?() }

    deinit { task?.cancel() }
}

extension Notification.Name {
    static let settingsOperationFailed = Notification.Name("settingsOperationFailed")
}
