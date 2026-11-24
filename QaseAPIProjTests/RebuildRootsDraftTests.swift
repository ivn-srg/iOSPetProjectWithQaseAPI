@testable import QaseAPIProj
import Testing
import UIKit

@Suite(.timeLimit(.minutes(1))) @MainActor
struct RebuildRootsDraftTests {
    @Test func dirtyDraftInPresentedStackIsReported() async {
        let fixture = PresentedStackFixture(hasUnsavedChanges: true)
        defer { fixture.tearDown() }
        await fixture.presentDraft()
        #expect(fixture.coordinator.hasUnsavedDrafts(inPresentedStackOf: fixture.root))
    }

    @Test func cleanDraftInPresentedStackIsNotReported() async {
        let fixture = PresentedStackFixture(hasUnsavedChanges: false)
        defer { fixture.tearDown() }
        await fixture.presentDraft()
        #expect(!fixture.coordinator.hasUnsavedDrafts(inPresentedStackOf: fixture.root))
    }

    @Test func rootWithoutPresentedControllerHasNoDrafts() {
        let fixture = PresentedStackFixture(hasUnsavedChanges: true)
        defer { fixture.tearDown() }
        #expect(!fixture.coordinator.hasUnsavedDrafts(inPresentedStackOf: fixture.root))
    }
}

@MainActor
private final class PresentedStackFixture {
    let root = UIViewController()
    let coordinator: ApplicationProjectCoordinator
    private let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
    private let draft = DraftScreen()
    private let defaultsDomains: TemporaryDefaults

    init(hasUnsavedChanges: Bool) {
        let session = SessionContext(ownerID: "owner")
        let defaultsDomains = TemporaryDefaults()
        self.defaultsDomains = defaultsDomains
        let defaults = defaultsDomains.make()
        let store = SelectedProjectStore(
            repository: ProjectsSource(.projects([])),
            cache: TestDependencies.cache(session: session),
            session: session,
            defaults: defaults
        )
        coordinator = ApplicationProjectCoordinator(store: store, session: session)
        draft.hasUnsavedChanges = hasUnsavedChanges
        window.rootViewController = root
        window.makeKeyAndVisible()
    }

    func presentDraft() async {
        root.present(UINavigationController(rootViewController: draft), animated: false)
        await waitForCondition { root.presentedViewController != nil }
    }

    func tearDown() {
        window.isHidden = true
    }
}

@Suite(.timeLimit(.minutes(1))) @MainActor
struct PresenterWhenReadyTests {
    @Test func controllerWithoutPresentationIsItsOwnPresenter() async {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let presenter = await host.presenterWhenReady()
        #expect(presenter === host)
    }

    @Test func presentedControllerBecomesPresenterAfterAnimatedPresentation() async {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 640))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let presented = UIViewController()
        host.present(presented, animated: true)
        let presenter = await host.presenterWhenReady()
        #expect(presenter === presented)
        #expect(presented.canPresentNow)
    }
}
