import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    static let recentLimit = 3
    @Published private(set) var project: ProjectSummary?
    @Published private(set) var metrics: ProjectMetrics?
    @Published private(set) var activeRun: ActiveRunSummary?
    @Published private(set) var recentCases: [RecentCaseItem] = []
    @Published private(set) var metricsLoading = false
    @Published private(set) var runLoading = false
    @Published private(set) var metricsError: String?
    @Published private(set) var runError: String?
    @Published private(set) var metricsUpdatedAt: Date?
    @Published private(set) var runUpdatedAt: Date?

    private let repository: HomeRepository
    private let cache: RealmManager
    private let selection: SelectedProjectStore
    var selectionStore: SelectedProjectStore { selection }
    private let session: SessionContext
    private let clock: () -> Date
    private var subscription: AnyCancellable?
    private var sessionSubscription: AnyCancellable?
    private var task: Task<Void, Never>?
    private var requestGeneration = 0
    private var isVisible = false

    var showingSavedData: Bool {
        (metricsError != nil && metricsUpdatedAt != nil) || (runError != nil && runUpdatedAt != nil) }

    var oldestUpdate: Date? { [metricsUpdatedAt, runUpdatedAt].compactMap { $0 }.min() }

    init(
        repository: HomeRepository,
        cache: RealmManager,
        selection: SelectedProjectStore,
        session: SessionContext,
        clock: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.cache = cache
        self.selection = selection
        self.session = session
        self.clock = clock
        project = selection.selectedProject
        subscription = selection.$selectedProject.sink { [weak self] selected in
            guard let self else { return }
            let changed = self.project?.code != selected?.code
            self.project = selected
            if changed {
                self.task?.cancel()
                self.requestGeneration += 1
                self.resetSections()
                self.loadCache()
                if self.isVisible { self.refresh() }
            }
        }
        sessionSubscription = NotificationCenter.default.publisher(for: .didInvalidateSession)
            .sink { [weak self] notification in
                guard let self, notification.object as AnyObject? === self.session else { return }
                self.task?.cancel()
                self.requestGeneration += 1
                self.project = nil
                self.resetSections()
            }
    }

    func appear() {
        isVisible = true
        loadCache()
        if task == nil { refresh() }
    }

    func disappear() { isVisible = false }

    func refresh() {
        task?.cancel()
        task = Task { [weak self] in await self?.reload() }
    }

    func reload() async {
        guard let code = project?.code else { return }
        requestGeneration += 1
        let generation = requestGeneration
        let stamp = session.capture()
        loadCache()
        metricsLoading = true
        runLoading = true
        metricsError = nil
        runError = nil
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let updated = try await self.repository.project(code: code)
                    guard self.accepts(code: code, generation: generation, stamp: stamp) else { return }
                    self.project = updated
                    self.metrics = updated.metrics
                    self.metricsUpdatedAt = self.clock()
                    self.selection.refreshSelection(updated)
                } catch {
                    guard self.accepts(code: code, generation: generation, stamp: stamp),
                          !(error is CancellationError) else { return }
                    self.metricsError = "Could not load overview".localized
                }
                if self
                    .accepts(code: code, generation: generation, stamp: stamp) { self.metricsLoading = false }
            }
            group.addTask { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let run = try await self.repository.activeRun(projectCode: code)
                    guard self.accepts(code: code, generation: generation, stamp: stamp) else { return }
                    self.activeRun = run
                    self.runUpdatedAt = self.clock()
                } catch {
                    guard self.accepts(code: code, generation: generation, stamp: stamp),
                          !(error is CancellationError) else { return }
                    self.runError = "Could not load active run".localized
                }
                if self.accepts(code: code, generation: generation, stamp: stamp) { self.runLoading = false }
            }
        }
        if accepts(code: code, generation: generation, stamp: stamp) {
            recentCases = Array(cache.getRecentCases(projectCode: code).prefix(Self.recentLimit))
            task = nil
        }
    }

    private func accepts(code: String, generation: Int, stamp: SessionStamp) -> Bool {
        requestGeneration == generation && project?.code == code && session.isCurrent(stamp) && !Task
            .isCancelled
    }

    private func loadCache() {
        guard let code = project?.code else { return }
        if let cached = cache.getProjectSummaries().first(where: { $0.code == code }),
           metricsUpdatedAt == nil {
            metrics = cached.metrics
        } else if metrics == nil { metrics = project?.metrics }
        if let snapshot = cache.getHomeSnapshot(projectCode: code) {
            if metricsUpdatedAt == nil { metricsUpdatedAt = snapshot.metricsUpdatedAt }
            if runUpdatedAt == nil {
                activeRun = snapshot.activeRun
                runUpdatedAt = snapshot.runUpdatedAt
            }
        }
        recentCases = Array(cache.getRecentCases(projectCode: code).prefix(Self.recentLimit))
    }

    private func resetSections() {
        metrics = nil
        activeRun = nil
        recentCases = []
        metricsUpdatedAt = nil
        runUpdatedAt = nil
        metricsError = nil
        runError = nil
        metricsLoading = false
        runLoading = false
    }
}
