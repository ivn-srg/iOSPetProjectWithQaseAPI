@testable import QaseAPIProj
import Testing
import UIKit

@Suite(.timeLimit(.minutes(1))) @MainActor
struct MainTabbarTabReselectTests {
    @Test func dirtyFormBlocksReselectUntilDepartureIsConfirmed() async {
        let fixture = TabbarFixture()
        fixture.screen.suspendsDeparture = true
        #expect(!fixture.reselect())
        await waitForCondition { fixture.screen.departureRequests == 1 }
        #expect(fixture.nav.viewControllers.count == 2)
        fixture.screen.answer(true)
        await waitForCondition { fixture.nav.viewControllers.count == 1 }
        #expect(fixture.nav.viewControllers.first === fixture.root)
    }

    @Test func reselectFinishesEditingBeforeReadingUnsavedChanges() {
        let fixture = TabbarFixture()
        fixture.screen.hasUnsavedChanges = false
        #expect(fixture.reselect())
        #expect(fixture.screen.finishEditingCalls == 1)
    }

    @Test func declinedDepartureKeepsTheStack() async {
        let fixture = TabbarFixture()
        fixture.screen.suspendsDeparture = true
        #expect(!fixture.reselect())
        await waitForCondition { fixture.screen.departureRequests == 1 }
        fixture.screen.answer(false)
        // Повторный тап снова запросит уход только после завершения первого Task.
        await waitForCondition {
            _ = fixture.reselect()
            return fixture.screen.departureRequests == 2
        }
        fixture.screen.answer(false)
        #expect(fixture.nav.viewControllers.count == 2)
        #expect(fixture.tabbar.selectedViewController === fixture.nav)
    }

    @Test func secondTapIsRejectedWhileDepartureIsPending() async {
        let fixture = TabbarFixture()
        fixture.screen.suspendsDeparture = true
        #expect(!fixture.reselect())
        await waitForCondition { fixture.screen.departureRequests == 1 }
        #expect(!fixture.reselect())
        #expect(!fixture.tabbar.tabBarController(fixture.tabbar, shouldSelect: fixture.otherNav))
        #expect(fixture.screen.departureRequests == 1)
        fixture.screen.answer(false)
    }

    @Test func cleanFormUsesStandardPopToRoot() {
        let fixture = TabbarFixture()
        fixture.screen.hasUnsavedChanges = false
        #expect(fixture.reselect())
        #expect(fixture.screen.departureRequests == 0)
        #expect(fixture.nav.viewControllers.count == 2)
    }

    @Test func rootOfStackIsNotIntercepted() {
        let fixture = TabbarFixture()
        fixture.nav.setViewControllers([fixture.root], animated: false)
        #expect(fixture.reselect())
    }

    @Test func savingDraftBlocksReselectWithoutAsking() {
        let fixture = TabbarFixture()
        fixture.screen.isSavingDraft = true
        #expect(!fixture.reselect())
        #expect(fixture.screen.departureRequests == 0)
        #expect(fixture.nav.viewControllers.count == 2)
    }
}

@MainActor
private final class TabbarFixture {
    let root = UIViewController()
    let screen = DraftScreen()
    let nav: UINavigationController
    let otherNav = UINavigationController(rootViewController: UIViewController())
    let tabbar: MainTabbarViewController

    init() {
        nav = UINavigationController(rootViewController: root)
        nav.pushViewController(screen, animated: false)
        // View не загружается: viewDidLoad вызвал бы router.start().
        tabbar = MainTabbarViewController(
            roots: [nav, otherNav],
            router: RouterStub(),
            session: SessionContext(ownerID: "owner")
        )
        tabbar.selectedViewController = nav
    }

    func reselect() -> Bool {
        tabbar.tabBarController(tabbar, shouldSelect: nav)
    }
}

@MainActor
private final class RouterStub: ApplicationRouting {
    func start() {}
    func selectProject(_ project: ProjectSummary) {}
    func manageProjects() {}
    func showCases(search: Bool) {}
    func showSuites() {}
    func showRuns() {}
    func showRun(id: Int) {}
    func showDefects() {}
    func showCase(reference: TestCaseReference) {}
    func openSuite(_ suite: TestListEntity, from model: TestEntitiesViewModel) {}
    func openAncestor(_ breadcrumb: RepositoryBreadcrumb, from model: TestEntitiesViewModel) {}
    func repositoryBack() {}
    func createEntity(in location: RepositoryLocation) {}
}
