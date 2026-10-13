import Foundation
@testable import QaseAPIProj
import Testing

struct AuthHTTPTests {
    @Test(arguments: [200, 204, 299, 401, 403, 429, 500])
    func authenticationPreservesHTTPMeaning(_ status: Int) async throws {
        let transport = AuthHTTPTransport(status: status)
        let network = APIManager(tokenProvider: { "stored" }, transport: transport)
        if (200 ... 299).contains(status) || status == 401 {
            #expect(try await network.auth(by: "candidate") == (status != 401))
        } else {
            do {
                _ = try await network.auth(by: "candidate")
                Issue.record("HTTP failure must be thrown instead of reported as a bad token")
            } catch let error as API.NetError {
                guard case .httpError(let code, let message, let retryAfter) = error else {
                    Issue.record("Wrong HTTP error type")
                    return
                }
                #expect(code == status && message == "fixture server message")
                #expect(retryAfter == (status == 429 ? 12 : nil))
            }
        }
        #expect(await transport.tokens == ["candidate"])
    }
    
    @Test func emptyInputDoesNotSendAndTransportFailuresPropagate() async throws {
        let transport = AuthHTTPTransport(status: 200, error: URLError(.notConnectedToInternet))
        let network = APIManager(tokenProvider: { "stored" }, transport: transport)
        #expect(try await network.auth(by: "") == false)
        #expect(await transport.tokens.isEmpty)
        do {
            _ = try await network.auth(by: "candidate")
            Issue.record("Transport failure must be propagated")
        } catch let error as URLError {
            #expect(error.code == .notConnectedToInternet)
        }
    }
    
    @Test @MainActor
    func missingHTTPResponseIsNotReportedAsInvalidCredentials() async throws {
        let transport = AuthHTTPTransport(status: 200, nonHTTP: true)
        let network = APIManager(tokenProvider: { "stored" }, transport: transport)
        do {
            _ = try await network.auth(by: "candidate")
            Issue.record("Non-HTTP response must fail")
        } catch let error as URLError {
            #expect(error.code == .badServerResponse)
        }
    }
    
    @Test @MainActor
    func loginAndReplacementFailuresDoNotCommitCredentials() async throws {
        for status in [401, 403, 429, 500] {
            let domain = "AuthHTTPTests." + UUID().uuidString
            let defaults = try #require(UserDefaults(suiteName: domain))
            defer { defaults.removePersistentDomain(forName: domain) }
            let storage = MemoryCredentialStorage()
            let session = SessionContext()
            let network = APIManager(
                tokenProvider: { storage.getCredential()?.token },
                transport: AuthHTTPTransport(status: status)
            )
            var sideEffects = 0
            let auth = AuthManager(
                userDefaults: defaults,
                credentialStore: storage,
                replacementDependencies: .init(
                    session: session,
                    authenticate: { token, _ in try await network.auth(by: token) },
                    clearCache: { sideEffects += 1 },
                    configureDemoMode: { _ in sideEffects += 1 },
                    notifyAuthChanged: { _ in sideEffects += 1 }
                )
            )
            do {
                try await auth.loggedIn(token: "candidate")
                Issue.record("Failed login must not commit")
            } catch {}
            #expect(storage.getCredential() == nil && session.ownerID == nil)
            #expect(!defaults.bool(forKey: "isUserLoggedIn") && sideEffects == 0)
            
            let original = AuthCredential(token: "original", ownerID: "owner")
            try storage.saveCredential(original)
            session.activate(ownerID: "owner")
            defaults.set(true, forKey: "isUserLoggedIn")
            let stamp = session.capture()
            do {
                _ = try await auth.validateReplacementToken("candidate")
                Issue.record("Failed replacement must not validate")
            } catch {}
            #expect(storage.getCredential() == original && session.capture() == stamp)
            #expect(defaults.bool(forKey: "isUserLoggedIn") && sideEffects == 0)
        }
    }
}

private actor AuthHTTPTransport: HTTPTransport {
    let status: Int
    let error: URLError?
    let nonHTTP: Bool
    private(set) var tokens: [String] = []
    
    init(status: Int, error: URLError? = nil, nonHTTP: Bool = false) {
        self.status = status
        self.error = error
        self.nonHTTP = nonHTTP
    }
    
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        tokens.append(request.value(forHTTPHeaderField: "Token") ?? "")
        if let error { throw error }
        let url = try #require(request.url)
        if nonHTTP {
            return (
                Data(),
                URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
            )
        }
        let response = try #require(HTTPURLResponse(
            url: url, statusCode: status, httpVersion: nil,
            headerFields: status == 429 ? ["Retry-After": "12"] : nil
        ))
        return (Data("{\"errorMessage\":\"fixture server message\"}".utf8), response)
    }
}
