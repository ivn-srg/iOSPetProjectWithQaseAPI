import RealmSwift
import UIKit

@MainActor
final class AppCompositionRoot {
    let session: SessionContext
    let preferences: AppSettingsStore
    let auth: AuthManager
    
    private let cache: RealmManager
    private let realNetwork: NetworkManager
    private let mockNetwork: NetworkManager
    private let bundle: Bundle
    private let defaults: UserDefaults
    private var authenticatedGraph: AuthenticatedGraph?

    init(
        defaults: UserDefaults = .standard,
        bundle: Bundle = .main,
        arguments: [String] = ProcessInfo.processInfo.arguments,
        credentialStorage: AuthCredentialStorage? = nil,
        urlSession: URLSession = .shared,
        cacheConfiguration: Realm.Configuration? = nil
    ) {
        let testing = arguments.contains("UITests")
        let storage: AuthCredentialStorage = credentialStorage ??
            (testing ? MemoryCredentialStorage() : KeychainService())
        let session = SessionContext()
        let configuration = cacheConfiguration ?? (testing
            ? Realm.Configuration(inMemoryIdentifier: "qase-ui-tests." + UUID().uuidString)
            : RealmManager.productionConfiguration())
        let cache = RealmManager(configuration: configuration, session: session)
        let realNetwork = APIManager(
            tokenProvider: { storage.getCredential()?.token },
            transport: URLSessionTransport(session: urlSession)
        )
        let mockNetwork = APIMockManager(bundle: bundle)
        self.bundle = bundle
        self.defaults = defaults
        self.session = session
        self.cache = cache
        self.realNetwork = realNetwork
        self.mockNetwork = mockNetwork
        preferences = AppSettingsStore(defaults: defaults)
        auth = AuthManager(
            userDefaults: defaults,
            credentialStore: storage,
            replacementDependencies: AuthReplacementDependencies(
                session: session,
                authenticate: { token, demo in
                    try await (demo ?
                        mockNetwork as NetworkManager :
                        realNetwork as NetworkManager)
                        .auth(by: token)
                },
                clearCache: {
                    try cache.clearAll() },
                configureDemoMode: {
                    cache.useDemoStore($0) },
                notifyAuthChanged: { cleanupFailed in
                    NotificationCenter.default
                        .post(
                            name: .didChangeAuthStatus,
                            object: session,
                            userInfo: ["cacheCleanupFailed": cleanupFailed]
                        )
                }
            ),
            usesTestTokenStore: testing
        )
    }

    func makeRootController() -> RootViewController {
        RootViewController(session: session, makeContent: { [self] in makeContent() })
    }

    private func makeContent() -> UIViewController {
        authenticatedGraph = nil
        guard auth.isUserLoggedIn() else { return AuthViewController(auth: auth) }
        let network = auth.isDemoMode ? mockNetwork : realNetwork
        let reportFailure: (String) -> Void = { [session] message in
            NotificationCenter.default.post(
                name: .settingsOperationFailed,
                object: session,
                userInfo: ["message": message]
            )
        }
        let repository = HomeRepository(
            network: network,
            dao: cache,
            session: session,
            onCacheFailure: {
                reportFailure("Could not update cached data. Fresh data remains available.".localized)
            }
        )
        let selection = SelectedProjectStore(
            repository: repository,
            cache: cache,
            session: session,
            defaults: defaults
        )
        let coordinator = ApplicationProjectCoordinator(store: selection, session: session)
        let catalog = SuiteCatalogLoader(repository: repository, dao: cache, session: session)
        let factory = FeatureScreenFactory(
            network: network,
            cache: cache,
            session: session,
            repository: repository,
            selection: selection,
            catalogLoader: catalog,
            auth: auth,
            preferences: preferences,
            bundle: bundle,
            prepareForChange: { await coordinator.prepareForChange(switchingProject: false) },
            reportFailure: reportFailure
        )
        let router = ApplicationRouter(
            factory: factory,
            selection: selection,
            coordinator: coordinator,
            session: session
        )
        let shell = MainTabbarViewController(
            roots: factory.makeRoots(router: router),
            router: router,
            session: session
        )
        router.attach(shell)
        authenticatedGraph = AuthenticatedGraph(shell: shell, factory: factory)
        return shell
    }
}

@MainActor
private struct AuthenticatedGraph {
    let shell: MainTabbarViewController
    let factory: FeatureScreenFactory
}
