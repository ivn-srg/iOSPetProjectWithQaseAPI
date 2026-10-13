import Foundation
@testable import QaseAPIProj
import Testing

@Suite @MainActor
struct TokenReplacementTests {
    private static let echoedToken = "echoed-fake-token"
    private static let rawErrorMessage = "Raw server fixture: echoed-fake-token"

    @Test func emptyTokenDoesNotReachValidationOrChangeState() async {
        let fixture = TokenReplacementFixture()
        do {
            _ = try await fixture.auth.validateReplacementToken(" \n\t ")
            Issue.record("An empty token must be rejected")
        } catch {
            #expect(error is API.NetError)
        }
        #expect(fixture.requests.isEmpty)
        fixture.expectPreserved()
    }

    @Test func invalidTokenPreservesCredentialsPreferencesCacheAndSession() async {
        let fixture = TokenReplacementFixture()
        fixture.authenticate = { _, _ in false }
        do {
            _ = try await fixture.auth.validateReplacementToken("invalid-fixture")
            Issue.record("Invalid credentials must be rejected")
        } catch {
            #expect(error is API.NetError)
        }
        fixture.expectPreserved()
    }

    @Test func networkFailurePreservesTheCurrentSession() async {
        let fixture = TokenReplacementFixture()
        fixture.authenticate = { _, _ in throw URLError(.notConnectedToInternet) }
        do {
            _ = try await fixture.auth.validateReplacementToken("replacement-fixture")
            Issue.record("An offline validation must fail")
        } catch let error as URLError {
            #expect(error.code == .notConnectedToInternet)
        } catch {
            Issue.record("Unexpected validation error")
        }
        fixture.expectPreserved()
    }

    @Test func validationTrimsInputAndLeavesStateUntouchedUntilCommit() async throws {
        let fixture = TokenReplacementFixture()
        _ = try await fixture.auth.validateReplacementToken(" \nreplacement-fixture\t ")
        #expect(fixture.requests.map(\.token) == ["replacement-fixture"])
        #expect(fixture.requests.map(\.demo) == [false])
        fixture.expectPreserved()
    }

    @Test func sameTrimmedTokenIsACompleteNoOp() async throws {
        let fixture = TokenReplacementFixture()
        let candidate = try await fixture.auth.validateReplacementToken(" old-fixture\n")
        let result = try fixture.auth.commitReplacementToken(candidate)
        #expect(!result.didChange)
        #expect(!result.cacheCleanupFailed)
        fixture.expectPreserved()
    }

    @Test func sameTokenFormSubmissionSkipsDraftGuardAndClosesWithoutChanges() async throws {
        let fixture = TokenReplacementFixture()
        var guardCalls = 0
        var draft = "Unsaved project draft"
        var closeCount = 0
        let form = TokenReplacementViewModel(auth: fixture.auth, prepareForChange: {
            guardCalls += 1
            draft = ""
            return true
        })
        form.token = " old-fixture\n"
        form.onClose = { closeCount += 1 }

        let task = try #require(form.save())
        await task.value

        #expect(guardCalls == 0)
        #expect(draft == "Unsaved project draft")
        #expect(closeCount == 1)
        #expect(form.token.isEmpty)
        #expect(!form.isSaving)
        #expect(form.errorMessage == nil)
        fixture.expectPreserved()
    }

    @Test func declinedDraftGuardAfterValidationLeavesFormAndSessionUntouched() async throws {
        let fixture = TokenReplacementFixture()
        var guardCalls = 0
        var draft = "Unsaved project draft"
        var closeCount = 0
        let form = TokenReplacementViewModel(auth: fixture.auth, prepareForChange: {
            guardCalls += 1
            #expect(fixture.requests.map(\.token) == ["replacement-fixture"])
            fixture.expectPreserved()
            return false
        })
        form.token = "replacement-fixture"
        form.onClose = {
            closeCount += 1
            draft = ""
        }

        let task = try #require(form.save())
        await task.value

        #expect(guardCalls == 1)
        #expect(draft == "Unsaved project draft")
        #expect(closeCount == 0)
        #expect(form.token == "replacement-fixture")
        #expect(!form.isSaving)
        #expect(form.errorMessage == nil)
        fixture.expectPreserved()
    }

    @Test func canceledFormCannotCommitAfterDraftGuardResumes() async throws {
        let fixture = TokenReplacementFixture()
        let gate = TokenValidationGate()
        var guardCalls = 0
        var closeCount = 0
        let form = TokenReplacementViewModel(auth: fixture.auth, prepareForChange: {
            guardCalls += 1
            return await gate.response()
        })
        form.token = "replacement-fixture"
        form.onClose = { closeCount += 1 }

        let task = try #require(form.save())
        await gate.waitUntilSuspended()
        #expect(fixture.requests.map(\.token) == ["replacement-fixture"])
        fixture.expectPreserved()
        form.cancel()
        gate.resume()
        await task.value

        #expect(guardCalls == 1)
        #expect(closeCount == 1)
        #expect(form.token.isEmpty)
        #expect(!form.isSaving)
        #expect(form.errorMessage == nil)
        fixture.expectPreserved()
    }

    @Test func invalidCredentialsShowSafeCheckTokenMessage() async throws {
        try await expectFormError(
            API.NetError.invalidCredantials,
            expectedMessage: "Could not update API token. Check the token and try again."
        )
    }

    @Test func unauthorizedResponseShowsSafeCheckTokenMessage() async throws {
        try await expectFormError(
            API.NetError.httpError(statusCode: 401, message: Self.rawErrorMessage, retryAfter: nil),
            expectedMessage: "Could not update API token. Check the token and try again."
        )
    }

    @Test func forbiddenResponseDoesNotClaimTheTokenIsInvalid() async throws {
        try await expectFormError(
            API.NetError.httpError(statusCode: 403, message: Self.rawErrorMessage, retryAfter: nil),
            expectedMessage: "Could not verify access with this token"
        )
    }

    @Test func offlineFailureShowsConnectionGuidance() async throws {
        try await expectFormError(
            API.NetError.noInternetConnection,
            expectedMessage: "Could not verify API token. Check your internet connection and try again."
        )
    }

    @Test func timeoutShowsRetryGuidance() async throws {
        try await expectFormError(
            API.NetError.timeout,
            expectedMessage: "Token verification timed out. Try again."
        )
    }

    @Test func nativeOfflineFailureShowsConnectionGuidance() async throws {
        try await expectFormError(
            URLError(.notConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: Self.rawErrorMessage]),
            expectedMessage: "Could not verify API token. Check your internet connection and try again."
        )
    }

    @Test func nativeTimeoutShowsRetryGuidance() async throws {
        try await expectFormError(
            URLError(.timedOut, userInfo: [NSLocalizedDescriptionKey: Self.rawErrorMessage]),
            expectedMessage: "Token verification timed out. Try again."
        )
    }

    @Test func keychainFailureShowsSaveGuidanceAndPreservesTheSession() async throws {
        try await expectFormError(
            KeychainError.unhandledError(status: -50),
            expectedMessage: "Could not save API token. Try again.",
            duringSave: true
        )
    }

    @Test func otherFailuresNeverExposeServerTextOrToken() async throws {
        let errors: [Error] = [
            API.NetError.otherNetworkError(Self.rawErrorMessage),
            API.NetError.httpError(statusCode: 500, message: Self.rawErrorMessage, retryAfter: nil),
            NSError(
                domain: "TokenFixture",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: Self.rawErrorMessage]
            )
        ]
        for error in errors {
            try await expectFormError(error, expectedMessage: "Could not update API token. Try again.")
        }
    }

    @Test func storageFailureOccursBeforeSessionOrCacheChanges() async throws {
        let fixture = TokenReplacementFixture()
        let candidate = try await fixture.auth.validateReplacementToken("replacement-fixture")
        fixture.storage.failSaving = true
        do {
            _ = try fixture.auth.commitReplacementToken(candidate)
            Issue.record("A storage failure must reject the commit")
        } catch {
            #expect(error is TokenFixtureError)
        }
        fixture.expectPreserved()
    }

    @Test func canceledValidationIgnoresEvenASuccessfulNetworkResponse() async {
        let fixture = TokenReplacementFixture()
        let gate = TokenValidationGate()
        fixture.authenticate = { _, _ in await gate.response() }
        let task = Task { try await fixture.auth.validateReplacementToken("replacement-fixture") }
        await gate.waitUntilSuspended()
        task.cancel()
        gate.resume()
        do {
            _ = try await task.value
            Issue.record("Canceled validation must not return a candidate")
        } catch {
            #expect(error is CancellationError)
        }
        fixture.expectPreserved()
    }

    @Test func cancellationBeforeCommitPreservesTheOldSession() async throws {
        let fixture = TokenReplacementFixture()
        let candidate = try await fixture.auth.validateReplacementToken("replacement-fixture")
        let task = Task { try fixture.auth.commitReplacementToken(candidate) }
        task.cancel()
        do {
            _ = try await task.value
            Issue.record("Canceled commit must not persist credentials")
        } catch {
            #expect(error is CancellationError)
        }
        fixture.expectPreserved()
    }

    @Test func sessionChangedDuringValidationRejectsItsLateResponse() async {
        let fixture = TokenReplacementFixture()
        let gate = TokenValidationGate()
        fixture.authenticate = { _, _ in await gate.response() }
        let task = Task { try await fixture.auth.validateReplacementToken("replacement-fixture") }
        await gate.waitUntilSuspended()
        fixture.session.activate(ownerID: "another-owner")
        let currentStamp = fixture.session.capture()
        gate.resume()
        do {
            _ = try await task.value
            Issue.record("A late response from the old session must be rejected")
        } catch {
            #expect(error is CancellationError)
        }
        fixture.expectPreserved(stamp: currentStamp)
    }

    @Test func sessionChangedAfterValidationCannotCommit() async throws {
        let fixture = TokenReplacementFixture()
        let candidate = try await fixture.auth.validateReplacementToken("replacement-fixture")
        fixture.session.invalidate()
        let currentStamp = fixture.session.capture()
        do {
            _ = try fixture.auth.commitReplacementToken(candidate)
            Issue.record("A candidate from an invalidated session must be rejected")
        } catch {
            #expect(error is CancellationError)
        }
        fixture.expectPreserved(stamp: currentStamp)
    }

    @Test func candidateCannotBeCommittedByAnotherManager() async throws {
        let first = TokenReplacementFixture()
        let second = TokenReplacementFixture()
        let candidate = try await first.auth.validateReplacementToken("replacement-fixture")
        do {
            _ = try second.auth.commitReplacementToken(candidate)
            Issue.record("A candidate belongs to the manager that validated it")
        } catch {
            #expect(error is CancellationError)
        }
        first.expectPreserved()
        second.expectPreserved()
    }

    @Test func successfulCommitPersistsBeforeCleanupAndActivatesBeforeNotification() async throws {
        let fixture = TokenReplacementFixture()
        fixture.onClearCache = { [unowned fixture] in
            #expect(fixture.storage.getCredential()?.token == "replacement-fixture")
            #expect(fixture.storage.getCredential()?.ownerID != fixture.original.ownerID)
            #expect(fixture.session.ownerID == nil)
            #expect(fixture.defaults.object(forKey: "selectedProject.old-owner") == nil)
            #expect(fixture.defaults.object(forKey: "selectedProject.another-owner") == nil)
        }
        fixture.onNotify = { [unowned fixture] in
            #expect(fixture.session.ownerID == fixture.storage.getCredential()?.ownerID)
            #expect(fixture.defaults.bool(forKey: "isUserLoggedIn"))
            #expect(fixture.configuredModes == [false])
        }
        let candidate = try await fixture.auth.validateReplacementToken("replacement-fixture")
        let result = try fixture.auth.commitReplacementToken(candidate)
        #expect(result.didChange)
        #expect(!result.cacheCleanupFailed)
        #expect(fixture.storage.savedRecords.count == 1)
        #expect(fixture.storage.deleteCount == 0)
        #expect(fixture.events == ["clear", "configure", "notify"])
        #expect(fixture.auth.getAuthToken() == "replacement-fixture")
        #expect(fixture.session.capture() != fixture.originalStamp)
        #expect(fixture.defaults.string(forKey: "appearancePreference") == "dark")
        #expect(fixture.defaults.bool(forKey: "featureFlag"))
        #expect(!fixture.cachedOldData)
        #expect(fixture.notifications == [false])
    }

    @Test func cleanupFailureStillActivatesAndNotifiesTheNewSession() async throws {
        let fixture = TokenReplacementFixture()
        fixture.failCacheCleanup = true
        let candidate = try await fixture.auth.validateReplacementToken("replacement-fixture")
        let result = try fixture.auth.commitReplacementToken(candidate)
        #expect(result.didChange)
        #expect(result.cacheCleanupFailed)
        #expect(fixture.storage.getCredential()?.token == "replacement-fixture")
        #expect(fixture.session.ownerID == fixture.storage.getCredential()?.ownerID)
        #expect(fixture.session.ownerID != fixture.original.ownerID)
        #expect(fixture.defaults.bool(forKey: "isUserLoggedIn"))
        #expect(fixture.defaults.object(forKey: "selectedProject.old-owner") == nil)
        #expect(fixture.defaults.string(forKey: "appearancePreference") == "dark")
        #expect(fixture.events == ["clear", "configure", "notify"])
        #expect(fixture.notifications == [true])
        #expect(fixture.cachedOldData)
    }

    @Test func replacementCanSwitchBetweenDemoAndRealServices() async throws {
        let fixture = TokenReplacementFixture()
        #expect(!fixture.auth.isDemoMode)
        let demoCandidate = try await fixture.auth.validateReplacementToken(" QASE_DEMO ")
        #expect(!fixture.auth.isDemoMode)
        _ = try fixture.auth.commitReplacementToken(demoCandidate)
        #expect(fixture.auth.isDemoMode)
        let realCandidate = try await fixture.auth.validateReplacementToken("real-fixture")
        #expect(fixture.auth.isDemoMode)
        _ = try fixture.auth.commitReplacementToken(realCandidate)
        #expect(!fixture.auth.isDemoMode)
        #expect(fixture.requests.map(\.demo) == [true, false])
        #expect(fixture.configuredModes == [true, false])
    }

    @Test func committedCandidateCannotBeReplayed() async throws {
        let fixture = TokenReplacementFixture()
        let candidate = try await fixture.auth.validateReplacementToken("replacement-fixture")
        _ = try fixture.auth.commitReplacementToken(candidate)
        let currentStamp = fixture.session.capture()
        do {
            _ = try fixture.auth.commitReplacementToken(candidate)
            Issue.record("A committed candidate must not be applied again")
        } catch {
            #expect(error is CancellationError)
        }
        #expect(fixture.storage.savedRecords.count == 1)
        #expect(fixture.session.capture() == currentStamp)
        #expect(fixture.notifications.count == 1)
    }

    private func expectFormError(
        _ error: Error,
        expectedMessage: String,
        duringSave: Bool = false
    ) async throws {
        let fixture = TokenReplacementFixture()
        if duringSave { fixture.storage.savingError = error }
        else { fixture.authenticate = { _, _ in throw error } }
        var guardCalls = 0
        var closeCount = 0
        let form = TokenReplacementViewModel(auth: fixture.auth, prepareForChange: {
            guardCalls += 1
            return true
        })
        form.token = Self.echoedToken
        form.onClose = { closeCount += 1 }

        let task = try #require(form.save())
        await task.value

        let message = try #require(form.errorMessage)
        #expect(message == expectedMessage.localized)
        #expect(!message.contains(Self.echoedToken))
        #expect(!message.contains(Self.rawErrorMessage))
        #expect(form.token == Self.echoedToken)
        #expect(!form.isSaving)
        #expect(guardCalls == (duringSave ? 1 : 0))
        #expect(closeCount == 0)
        fixture.expectPreserved()
    }
}

private enum TokenFixtureError: Error { case storage, cleanup }

private final class TokenCredentialStorage: AuthCredentialStorage {
    private let lock = NSLock()
    private var record: AuthCredential?
    var failSaving = false
    var savingError: Error?
    private(set) var savedRecords: [AuthCredential] = []
    private(set) var deleteCount = 0

    init(_ credential: AuthCredential) { record = credential }

    func getCredential() -> AuthCredential? {
        lock.lock()
        defer { lock.unlock() }
        return record
    }

    func saveCredential(_ credential: AuthCredential) throws {
        lock.lock()
        defer { lock.unlock() }
        if let savingError { throw savingError }
        guard !failSaving else { throw TokenFixtureError.storage }
        record = credential
        savedRecords.append(credential)
    }

    func deleteToken() throws {
        lock.lock()
        defer { lock.unlock() }
        record = nil
        deleteCount += 1
    }
}

@MainActor
private final class TokenReplacementFixture {
    let original: AuthCredential
    let session: SessionContext
    let defaults: UserDefaults
    let storage: TokenCredentialStorage
    let originalStamp: SessionStamp
    var authenticate: (String, Bool) async throws -> Bool = { _, _ in true }
    var requests: [(token: String, demo: Bool)] = []
    var events: [String] = []
    var cachedOldData = true
    var failCacheCleanup = false
    var configuredModes: [Bool] = []
    var notifications: [Bool] = []
    var onClearCache: (() -> Void)?
    var onNotify: (() -> Void)?

    lazy var auth = AuthManager(
        userDefaults: defaults,
        credentialStore: storage,
        replacementDependencies: AuthReplacementDependencies(
            session: session,
            authenticate: { [unowned self] token, demo in
                requests.append((token, demo))
                return try await authenticate(token, demo)
            },
            clearCache: { [unowned self] in
                events.append("clear")
                onClearCache?()
                if failCacheCleanup { throw TokenFixtureError.cleanup }
                cachedOldData = false
            },
            configureDemoMode: { [unowned self] demo in
                events.append("configure")
                configuredModes.append(demo)
            },
            notifyAuthChanged: { [unowned self] cleanupFailed in
                events.append("notify")
                notifications.append(cleanupFailed)
                onNotify?()
            }
        )
    )

    init() {
        let original = AuthCredential(token: "old-fixture", ownerID: "old-owner")
        let session = SessionContext(ownerID: "old-owner")
        self.original = original
        self.session = session
        defaults = UserDefaults(suiteName: "TokenReplacementTests." + UUID().uuidString)!
        storage = TokenCredentialStorage(original)
        originalStamp = session.capture()
        defaults.set(true, forKey: "isUserLoggedIn")
        defaults.set("OLD", forKey: "selectedProject.old-owner")
        defaults.set("OTHER", forKey: "selectedProject.another-owner")
        defaults.set("dark", forKey: "appearancePreference")
        defaults.set(true, forKey: "featureFlag")
    }

    func expectPreserved(stamp: SessionStamp? = nil) {
        #expect(storage.getCredential() == original)
        #expect(storage.savedRecords.isEmpty)
        #expect(storage.deleteCount == 0)
        #expect(session.capture() == (stamp ?? originalStamp))
        #expect(defaults.bool(forKey: "isUserLoggedIn"))
        #expect(defaults.string(forKey: "selectedProject.old-owner") == "OLD")
        #expect(defaults.string(forKey: "selectedProject.another-owner") == "OTHER")
        #expect(defaults.string(forKey: "appearancePreference") == "dark")
        #expect(defaults.bool(forKey: "featureFlag"))
        #expect(cachedOldData)
        #expect(events.isEmpty)
        #expect(configuredModes.isEmpty)
        #expect(notifications.isEmpty)
    }
}

@MainActor
private final class TokenValidationGate {
    private var responseContinuation: CheckedContinuation<Bool, Never>?
    private var suspendedWaiter: CheckedContinuation<Void, Never>?

    func response() async -> Bool {
        await withCheckedContinuation { continuation in
            responseContinuation = continuation
            suspendedWaiter?.resume()
            suspendedWaiter = nil
        }
    }

    func waitUntilSuspended() async {
        guard responseContinuation == nil else { return }
        await withCheckedContinuation { suspendedWaiter = $0 }
    }

    func resume() {
        responseContinuation?.resume(returning: true)
        responseContinuation = nil
    }
}
