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

    // Ловит: удаление guard `session.isCurrent(stamp)` после запроса страницы (:53).
    @Test func sessionChangeDuringFirstPageStopsTheWalkWithoutPublishing() async {
        let fixture = StoreFixture(cached: [], network: .suspended([a, b]))
        defer { fixture.tearDown() }
        fixture.source.pages = [0: [a, b], 2: [c]]
        fixture.source.pagesTotal = 3
        fixture.defaults.set("B", forKey: fixture.preferenceKey)
        let loading = Task { await fixture.store.load() }
        await waitForCondition { fixture.source.requests == 1 }
        fixture.session.invalidate()
        fixture.source.release()
        await loading.value
        #expect(fixture.source.requests == 1)
        #expect(fixture.store.projects.isEmpty)
        #expect(fixture.store.selectedProject == nil)
        #expect(fixture.store.errorMessage == nil)
        #expect(!fixture.store.isLoading)
        #expect(fixture.defaults.string(forKey: fixture.preferenceKey) == "B")
        #expect(fixture.defaults.string(forKey: "selectedProject.signed-out") == nil)
        #expect(fixture.selectionChanges == 0)
    }

    // Ловит: удаление guard `session.isCurrent(stamp)` в ветке ошибки (:71).
    @Test func lateFailureAfterSessionChangeDoesNotSetErrorMessage() async {
        let fixture = StoreFixture(cached: [], network: .suspendedFailure)
        defer { fixture.tearDown() }
        let loading = Task { await fixture.store.load() }
        await waitForCondition { fixture.source.requests == 1 }
        fixture.session.invalidate()
        fixture.source.release()
        await loading.value
        #expect(fixture.store.errorMessage == nil)
        #expect(fixture.store.selectedProject == nil)
        #expect(!fixture.store.isLoading)
    }

    // Ловит: удаление guard `session.isCurrent(originStamp)` в `commit` (:79).
    @Test func commitAfterSessionChangeDoesNotWritePreferenceOfTheNewOwner() {
        let fixture = StoreFixture(cached: [], network: .projects([a]))
        defer { fixture.tearDown() }
        fixture.session.invalidate()
        fixture.session.activate(ownerID: "new-owner")
        fixture.store.commit(a)
        #expect(fixture.store.selectedProject == nil)
        #expect(fixture.defaults.string(forKey: "selectedProject.new-owner") == nil)
        #expect(fixture.defaults.string(forKey: "selectedProject.signed-out") == nil)
        #expect(fixture.defaults.string(forKey: fixture.preferenceKey) == nil)
        #expect(fixture.selectionChanges == 0)
    }

    // Ловит: удаление guard на пустые `unique` при непустой странице (:55-57), из-за чего
    // страница из дублей молча принимается как последняя.
    @Test func pageMadeOnlyOfDuplicatesFailsTheLoadInsteadOfHanging() async {
        let fixture = StoreFixture(cached: [], network: .projects([a, b]))
        defer { fixture.tearDown() }
        fixture.source.pages = [0: [a, b], 2: [a, b]]
        fixture.source.pagesTotal = 4
        await fixture.store.load()
        #expect(fixture.source.offsets == [0, 2])
        #expect(fixture.store.errorMessage == "Could not load projects".localized)
        #expect(fixture.store.projects.isEmpty)
        #expect(!fixture.store.isLoading)
    }

    // Ловит: `throw` на любом дубле вместо отбрасывания дублей (страница `[b, c]` после `[a, b]`).
    @Test func partiallyDuplicatedSecondPageIsMergedWithoutDuplicates() async {
        let fixture = StoreFixture(cached: [], network: .projects([a, b]))
        defer { fixture.tearDown() }
        fixture.source.pages = [0: [a, b], 2: [b, c]]
        fixture.source.pagesTotal = 4
        await fixture.store.load()
        #expect(fixture.source.offsets == [0, 2])
        #expect(fixture.store.errorMessage == nil)
        #expect(fixture.store.projects.map(\.code) == ["A", "B", "C"])
    }

    // Ловит: `changed` считается по равенству проекта, а не по коду (колбэк на смену title),
    // и колбэк, который не срабатывает при смене A -> B.
    @Test func selectionChangedFiresOnlyWhenTheCodeChanges() async {
        let fixture = StoreFixture(cached: [], network: .projects([a, b]))
        defer { fixture.tearDown() }
        await fixture.store.load()
        #expect(fixture.store.selectedProject?.code == "A")
        #expect(fixture.selectionChanges == 1)
        fixture.source.mode = .projects([ProjectSummary(title: "A renamed", code: "A"), b])
        await fixture.store.load()
        #expect(fixture.store.selectedProject?.title == "A renamed")
        #expect(fixture.selectionChanges == 1)
        fixture.store.commit(b)
        #expect(fixture.store.selectedProject?.code == "B")
        #expect(fixture.selectionChanges == 2)
        fixture.store.commit(ProjectSummary(title: "B renamed", code: "B"))
        #expect(fixture.selectionChanges == 2)
    }

    // Ловит: удаление проверки кода в `refreshSelection` (чужой проект подменяет выбор)
    // и отсутствие обновления элемента `projects`.
    @Test func refreshSelectionUpdatesOnlyTheSelectedCode() async {
        let fixture = StoreFixture(cached: [], network: .projects([a, b]))
        defer { fixture.tearDown() }
        await fixture.store.load()
        fixture.store.refreshSelection(ProjectSummary(title: "A updated", code: "A"))
        #expect(fixture.store.selectedProject?.title == "A updated")
        #expect(fixture.store.projects.map(\.title) == ["A updated", "B"])
        fixture.store.refreshSelection(ProjectSummary(title: "B updated", code: "B"))
        #expect(fixture.store.selectedProject?.code == "A")
        #expect(fixture.store.selectedProject?.title == "A updated")
        #expect(fixture.store.projects.map(\.title) == ["A updated", "B"])
        #expect(fixture.selectionChanges == 1)
    }

    // Ловит: удаление `errorMessage = nil` в начале `load` (:42).
    @Test func successfulLoadClearsThePreviousErrorMessage() async {
        let fixture = StoreFixture(cached: [], network: .failure)
        defer { fixture.tearDown() }
        await fixture.store.load()
        #expect(fixture.store.errorMessage != nil)
        fixture.source.mode = .projects([a])
        await fixture.store.load()
        #expect(fixture.store.errorMessage == nil)
        #expect(fixture.store.selectedProject?.code == "A")
    }
}

@MainActor
private final class StoreFixture {
    let store: SelectedProjectStore
    let source: ProjectsSource
    let session: SessionContext
    let defaults: UserDefaults
    private let suiteName = UUID().uuidString
    private(set) var requestedSelections = 0
    private(set) var selectionChanges = 0
    var preferenceKey: String { "selectedProject.owner" }

    init(cached: [ProjectSummary], network: ProjectsSource.Mode) {
        let session = SessionContext(ownerID: "owner")
        self.session = session
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
