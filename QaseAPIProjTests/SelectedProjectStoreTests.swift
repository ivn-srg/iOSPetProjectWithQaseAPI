import Foundation
@testable import QaseAPIProj
import Testing

@Suite(.timeLimit(.minutes(1))) @MainActor
struct SelectedProjectStoreTests {
    private let a = ProjectSummary(title: "A", code: "A")
    private let b = ProjectSummary(title: "B", code: "B")
    private let c = ProjectSummary(title: "C", code: "C")

    @Test func emptySelectionIsFilledFromCacheWithoutAskingForConfirmation() async {
        let fixture = StoreFixture(cached: [a, b], network: .projects([a, b]))
        defer { fixture.tearDown() }
        await fixture.store.load()
        #expect(fixture.store.selectedProject?.code == "A")
        #expect(fixture.requestedSelections == 0)
        #expect(fixture.selectionChanges == 1)
    }

    @Test func emptySelectionIsFilledFromNetworkWhenCacheIsEmpty() async {
        let fixture = StoreFixture(cached: [], network: .projects([a, b]))
        defer { fixture.tearDown() }
        await fixture.store.load()
        #expect(fixture.store.selectedProject?.code == "A")
        #expect(fixture.requestedSelections == 0)
        #expect(fixture.selectionChanges == 1)
    }

    @Test func savedProjectSurvivesEmptyCacheUntilNetworkAnswers() async {
        let fixture = StoreFixture(cached: [], network: .suspended([a, b]))
        defer { fixture.tearDown() }
        fixture.defaults.set("B", forKey: fixture.preferenceKey)
        let loading = Task { await fixture.store.load() }
        await waitForCondition { fixture.source.requests == 1 }
        #expect(fixture.defaults.string(forKey: fixture.preferenceKey) == "B")
        #expect(fixture.store.selectedProject == nil)
        fixture.source.release()
        await loading.value
        #expect(fixture.store.selectedProject?.code == "B")
        #expect(fixture.defaults.string(forKey: fixture.preferenceKey) == "B")
    }

    @Test func savedProjectMissingFromPartialCacheIsNotReplacedBeforeNetworkAnswers() async {
        let fixture = StoreFixture(cached: [a], network: .suspended([a, b]))
        defer { fixture.tearDown() }
        fixture.defaults.set("B", forKey: fixture.preferenceKey)
        let loading = Task { await fixture.store.load() }
        await waitForCondition { fixture.source.requests == 1 }
        #expect(fixture.store.selectedProject == nil)
        #expect(fixture.defaults.string(forKey: fixture.preferenceKey) == "B")
        fixture.source.release()
        await loading.value
        #expect(fixture.store.selectedProject?.code == "B")
    }

    @Test func savedProjectSurvivesFailedFirstLoad() async {
        let fixture = StoreFixture(cached: [], network: .failure)
        defer { fixture.tearDown() }
        fixture.defaults.set("B", forKey: fixture.preferenceKey)
        await fixture.store.load()
        #expect(fixture.defaults.string(forKey: fixture.preferenceKey) == "B")
        #expect(fixture.store.selectedProject == nil)
        #expect(fixture.store.errorMessage != nil)
    }

    @Test func failedLoadSelectsFirstCachedProjectWithoutOverwritingPreference() async {
        let fixture = StoreFixture(cached: [a, b], network: .failure)
        defer { fixture.tearDown() }
        fixture.defaults.set("C", forKey: fixture.preferenceKey)
        await fixture.store.load()
        #expect(fixture.store.selectedProject?.code == "A")
        #expect(fixture.defaults.string(forKey: fixture.preferenceKey) == "C")
        #expect(fixture.store.errorMessage != nil)
    }

    @Test func savedPreferenceWinsOverOfflineFallbackWhenNetworkReturns() async {
        let fixture = StoreFixture(cached: [a, b], network: .failure)
        defer { fixture.tearDown() }
        fixture.defaults.set("C", forKey: fixture.preferenceKey)
        await fixture.store.load()
        fixture.source.mode = .projects([a, b, c])
        await fixture.store.load()
        #expect(fixture.requestedSelections == 1)
        #expect(fixture.defaults.string(forKey: fixture.preferenceKey) == "C")
    }

    @Test func deletingTheOnlySelectedProjectClearsSelectionAndPreference() async {
        let fixture = StoreFixture(cached: [a], network: .projects([a]))
        defer { fixture.tearDown() }
        fixture.store.onSelectionRequested = nil
        await fixture.store.load()
        #expect(fixture.store.selectedProject?.code == "A")
        await fixture.store.didDeleteProject(code: "A")
        #expect(fixture.store.selectedProject == nil)
        #expect(fixture.defaults.string(forKey: fixture.preferenceKey) == nil)
    }

    @Test func confirmedEmptyListClearsStalePreference() async {
        let fixture = StoreFixture(cached: [], network: .projects([]))
        defer { fixture.tearDown() }
        fixture.defaults.set("B", forKey: fixture.preferenceKey)
        await fixture.store.load()
        #expect(fixture.store.selectedProject == nil)
        #expect(fixture.defaults.string(forKey: fixture.preferenceKey) == nil)
    }
}

@MainActor
private final class StoreFixture {
    let store: SelectedProjectStore
    let source: ProjectsSource
    let defaults: UserDefaults
    private let suiteName = UUID().uuidString
    private(set) var requestedSelections = 0
    private(set) var selectionChanges = 0
    var preferenceKey: String { "selectedProject.owner" }

    init(cached: [ProjectSummary], network: ProjectsSource.Mode) {
        let session = SessionContext(ownerID: "owner")
        let cache = TestDependencies.cache(session: session)
        _ = cache.saveProjectSummaries(cached, stamp: session.capture())
        source = ProjectsSource(network)
        defaults = UserDefaults(suiteName: suiteName)!
        store = SelectedProjectStore(repository: source, cache: cache, session: session, defaults: defaults)
        store.onSelectionRequested = { [weak self] _ in
            self?.requestedSelections += 1
            return true
        }
        store.onSelectionChanged = { [weak self] in self?.selectionChanges += 1 }
    }

    func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
