import Combine
import SwiftUI

@MainActor
final class PagedReadViewModel<Item: Codable & Identifiable>: ObservableObject {
    @Published private(set) var items: [Item] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var usingCache = false
    @Published private(set) var hasMore = true
    @Published var query = ""

    private let session: SessionContext
    private let fetch: (String, Int) async throws -> QaseAPIListResult<Item>
    private let cached: ((String) -> [Item]?)?
    private var generation = 0
    private var nextOffset = 0
    private var hasAppeared = false
    private var searchTask: Task<Void, Never>?
    private var sessionSubscription: AnyCancellable?

    init(
        session: SessionContext,
        cached: ((String) -> [Item]?)? = nil,
        fetch: @escaping (String, Int) async throws -> QaseAPIListResult<Item>
    ) {
        self.session = session
        self.cached = cached
        self.fetch = fetch
        sessionSubscription = NotificationCenter.default.publisher(for: .didInvalidateSession)
            .sink { [weak self] notification in
                guard let self, notification.object as AnyObject? === self.session else { return }
                self.generation += 1
                self.searchTask?.cancel()
                self.items = []
                self.isLoading = false
                self.usingCache = false
                self.errorMessage = nil
                self.hasMore = false
            }
    }

    func appear() async {
        guard !hasAppeared else { return }
        hasAppeared = true
        items = cached?(query) ?? []
        await reload()
    }

    func searchChanged() {
        generation += 1
        searchTask?.cancel()
        items = cached?(query) ?? []
        usingCache = false
        errorMessage = nil
        isLoading = false
        searchTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(300)) }
            catch { return }
            await self?.reload()
        }
    }

    func reload() async {
        guard session.ownerID != nil else { return }
        generation += 1
        nextOffset = 0
        hasMore = true
        await load(reset: true)
    }

    func loadMore() async {
        guard !isLoading, hasMore, !usingCache else { return }
        await load(reset: false)
    }

    private func load(reset: Bool) async {
        let requestGeneration = generation
        let requestedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let offset = reset ? 0 : nextOffset
        let stamp = session.capture()
        isLoading = true
        errorMessage = nil
        defer {
            if generation == requestGeneration { isLoading = false }
        }
        do {
            let page = try await fetch(requestedQuery, offset)
            guard generation == requestGeneration,
                  query.trimmingCharacters(in: .whitespacesAndNewlines) == requestedQuery,
                  session.isCurrent(stamp), !Task.isCancelled else { return }
            if reset { items = [] }
            var ids = Set(items.map(\.id))
            items.append(contentsOf: page.entities.filter { ids.insert($0.id).inserted })
            nextOffset = offset + page.entities.count
            hasMore = !page.entities
                .isEmpty &&
                ((page.filtered ?? page.total).map { nextOffset < $0 } ?? (page.entities.count == 50))
            usingCache = false
        } catch {
            guard generation == requestGeneration, session.isCurrent(stamp), !Task.isCancelled,
                  !(error is CancellationError) else { return }
            if reset, let cachedItems = cached?(requestedQuery) {
                items = cachedItems
                usingCache = true
                hasMore = false
            }
            errorMessage = "Could not load data".localized
        }
    }
}

private struct ReadListSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< 3, id: \.self) { index in
                HStack(alignment: .top, spacing: AppTheme.Space.medium) {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.control)
                        .fill(Color(uiColor: AppTheme.Palette.secondarySurface))
                        .frame(width: AppTheme.Size.touch, height: AppTheme.Size.touch)
                    VStack(alignment: .leading, spacing: AppTheme.Space.tiny) {
                        RoundedRectangle(cornerRadius: AppTheme.Space.tiny).frame(width: 160, height: 20)
                        RoundedRectangle(cornerRadius: AppTheme.Space.tiny).frame(width: 80, height: 12)
                        RoundedRectangle(cornerRadius: AppTheme.Space.tiny).frame(width: 120, height: 12)
                    }
                    .foregroundStyle(Color(uiColor: AppTheme.Palette.secondarySurface))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(AppTheme.Space.regular).frame(minHeight: 80)
                if index < 2 { Divider().padding(.leading, AppTheme.Space.regular) }
            }
        }
        .background(
            Color(uiColor: AppTheme.Palette.surface),
            in: RoundedRectangle(cornerRadius: AppTheme.Radius.card)
        )
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.card)
            .stroke(Color(uiColor: AppTheme.Palette.border)))
        .accessibilityElement(children: .ignore).accessibilityLabel("Loading".localized)
        .accessibilityIdentifier("work.loading")
        .allowsHitTesting(false)
    }
}

private struct ReadListContent<Item: Codable & Identifiable, Row: View>: View {
    @ObservedObject var model: PagedReadViewModel<Item>
    let projectTitle: String
    let emptyTitle: String
    @ViewBuilder let row: (Item) -> Row

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Space.regular) {
                Text(projectTitle).font(.subheadline)
                    .foregroundStyle(Color(uiColor: AppTheme.Palette.secondaryText))
                    .accessibilityIdentifier("work.project")
                if model.usingCache {
                    HomeStateView(
                        title: "Showing saved data".localized,
                        symbol: "arrow.triangle.2.circlepath",
                        message: "Some data could not be refreshed".localized
                    )
                }
                if model.isLoading && model.items.isEmpty { ReadListSkeleton() }
                else if model.items.isEmpty && model.errorMessage == nil {
                    HomeStateView(title: emptyTitle, symbol: "tray")
                }
                if !model.items.isEmpty {
                    LazyVStack(spacing: 0) {
                        ForEach(model.items) { item in
                            row(item)
                            if item.id != model.items.last?.id { Divider().padding(
                                .leading,
                                AppTheme.Space.regular
                            ) }
                        }
                    }
                    .background(
                        Color(uiColor: AppTheme.Palette.surface),
                        in: RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    )
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                        .stroke(Color(uiColor: AppTheme.Palette.border)))
                }
                if let error = model.errorMessage {
                    HomeStateView(
                        title: error,
                        symbol: "exclamationmark.triangle",
                        actionTitle: "Retry".localized
                    ) { Task { await model.reload() } }
                }
                if model.hasMore && !model.items.isEmpty && !model.usingCache {
                    if model.isLoading { ProgressView().frame(maxWidth: .infinity) }
                    else { Button("Load more".localized) { Task { await model.loadMore() } }.frame(
                        maxWidth: .infinity,
                        minHeight: AppTheme.Size.touch
                    ) }
                }
            }
            .frame(maxWidth: AppTheme.Size.content)
            .padding(AppTheme.Space.screen).frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: AppTheme.Palette.canvas))
        .foregroundStyle(Color(uiColor: AppTheme.Palette.text))
        .tint(Color(uiColor: AppTheme.Palette.accent))
        .task { await model.appear() }
        .refreshable { await model.reload() }
    }
}

struct RunListView: View {
    private let projectCode: String
    @ObservedObject private var selection: SelectedProjectStore
    private let onRun: (Int) -> Void
    @StateObject private var model: PagedReadViewModel<RunReadDTO>

    init(
        projectCode: String,
        selection: SelectedProjectStore,
        repository: HomeRepository,
        session: SessionContext = .shared,
        onRun: @escaping (Int) -> Void
    ) {
        self.projectCode = projectCode
        self.selection = selection
        self.onRun = onRun
        _model = StateObject(wrappedValue: PagedReadViewModel(session: session, cached: { _ in
            repository.hasCachedRuns(projectCode: projectCode) ? repository
                .cachedRuns(projectCode: projectCode) : nil
        }) { _, offset in
            try await repository.runs(projectCode: projectCode, offset: offset)
        })
    }

    var body: some View {
        ReadListContent(
            model: model,
            projectTitle: selection.projects.first(where: { $0.code == projectCode })?.title ?? projectCode,
            emptyTitle: "No runs".localized
        ) { run in
            EntityRow(
                identifier: "\(projectCode)-\(run.id)",
                title: run.title,
                description: run.statusText?.localized,
                symbol: "play.circle"
            ) { onRun(run.id) }
        }
    }
}

struct DefectListView: View {
    private let projectCode: String
    @ObservedObject private var selection: SelectedProjectStore
    private let onDefect: (Int) -> Void
    @StateObject private var model: PagedReadViewModel<DefectReadDTO>

    init(
        projectCode: String,
        selection: SelectedProjectStore,
        repository: HomeRepository,
        session: SessionContext = .shared,
        onDefect: @escaping (Int) -> Void
    ) {
        self.projectCode = projectCode
        self.selection = selection
        self.onDefect = onDefect
        _model = StateObject(wrappedValue: PagedReadViewModel(session: session, cached: { _ in
            repository.hasCachedDefects(projectCode: projectCode) ? repository
                .cachedDefects(projectCode: projectCode) : nil
        }) { _, offset in
            try await repository.defects(projectCode: projectCode, offset: offset)
        })
    }

    var body: some View {
        ReadListContent(
            model: model,
            projectTitle: selection.projects.first(where: { $0.code == projectCode })?.title ?? projectCode,
            emptyTitle: "No defects".localized
        ) { defect in
            EntityRow(
                identifier: "\(projectCode)-\(defect.id)",
                title: defect.title,
                description: [defect.severity, defect.status].compactMap { $0?.localized }
                    .joined(separator: " · "),
                symbol: "ladybug"
            ) { onDefect(defect.id) }
        }
    }
}

struct RunDetailView: View {
    let projectCode: String
    let runID: Int
    let repository: HomeRepository
    var session: SessionContext = .shared
    let onCase: (TestCaseReference) -> Void
    @State private var run: RunReadDTO?
    @State private var errorMessage: String?
    @State private var loading = false
    @State private var usingCache = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Space.section) {
                if let run {
                    if usingCache { HomeStateView(
                        title: "Showing saved data".localized,
                        symbol: "arrow.triangle.2.circlepath"
                    ) }
                    Text(run.title).font(AppTheme.Typography.screen)
                    if let status = run.statusText { StatusBadge(
                        title: status.localized,
                        symbol: "play.circle",
                        tone: .neutral
                    ) }
                    if let startTime = run.startTime { Text("Started".localized + " " + startTime.formatted(
                        date: .abbreviated,
                        time: .shortened
                    )).font(.footnote) }
                    if let progress = run.stats?
                        .progress { ProgressRing(progress: progress).frame(maxWidth: .infinity) }
                    else { HomeStateView(
                        title: "Progress unavailable".localized,
                        symbol: "questionmark.circle"
                    ) }
                    SectionHeader(title: "Cases".localized)
                    if let cases = run.cases, !cases.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(cases, id: \.self) { id in
                                EntityRow(
                                    identifier: "\(projectCode)-\(id)",
                                    title: "Case".localized + " \(id.formatted())"
                                ) { onCase(TestCaseReference(projectCode: projectCode, caseID: id)) }
                                    .accessibilityIdentifier("\(projectCode)-\(id)")
                                if id != cases.last { Divider() }
                            }
                        }.background(
                            Color(uiColor: AppTheme.Palette.surface),
                            in: RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                        )
                    } else {
                        HomeStateView(
                            title: (run.cases == nil ? "Cases unavailable" : "No cases").localized,
                            symbol: "doc"
                        )
                    }
                } else if loading { HomeSkeleton() }
                if let errorMessage {
                    HomeStateView(
                        title: errorMessage,
                        symbol: "exclamationmark.triangle",
                        actionTitle: "Retry".localized
                    ) { Task { await load() } }
                }
            }.frame(maxWidth: AppTheme.Size.content).padding(AppTheme.Space.screen).frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: AppTheme.Palette.canvas))
        .foregroundStyle(Color(uiColor: AppTheme.Palette.text))
        .tint(Color(uiColor: AppTheme.Palette.accent))
        .task { await load() }.refreshable { await load() }
    }

    private func load() async {
        guard !loading else { return }
        let stamp = session.capture()
        if run == nil { run = repository.cachedRun(projectCode: projectCode, id: runID) }
        loading = true
        errorMessage = nil
        defer { loading = false }
        do {
            let result = try await repository.run(projectCode: projectCode, id: runID)
            guard session.isCurrent(stamp), !Task.isCancelled else { return }
            run = result
            usingCache = false
        } catch {
            guard session.isCurrent(stamp), !Task.isCancelled, !(error is CancellationError) else { return }
            errorMessage = "Could not load run".localized
            usingCache = run != nil
        }
    }
}

struct DefectDetailView: View {
    let projectCode: String
    let defectID: Int
    let repository: HomeRepository
    var session: SessionContext = .shared
    @State private var defect: DefectReadDTO?
    @State private var errorMessage: String?
    @State private var loading = false
    @State private var usingCache = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Space.section) {
                if let defect {
                    if usingCache { HomeStateView(
                        title: "Showing saved data".localized,
                        symbol: "arrow.triangle.2.circlepath"
                    ) }
                    Text(defect.title).font(AppTheme.Typography.screen)
                    if let severity = defect.severity { StatusBadge(
                        title: "Severity".localized + ": " + severity.localized,
                        symbol: "exclamationmark.circle"
                    ) }
                    if let status = defect.status { StatusBadge(
                        title: "Status".localized + ": " + status.localized,
                        symbol: "circle"
                    ) }
                    SectionHeader(title: "Actual result".localized)
                    Text(defect.actualResult ?? "Unavailable".localized).font(AppTheme.Typography.body)
                        .textSelection(.enabled)
                } else if loading { HomeSkeleton() }
                if let errorMessage {
                    HomeStateView(
                        title: errorMessage,
                        symbol: "exclamationmark.triangle",
                        actionTitle: "Retry".localized
                    ) { Task { await load() } }
                }
            }.frame(maxWidth: AppTheme.Size.content).padding(AppTheme.Space.screen).frame(maxWidth: .infinity)
        }
        .background(Color(uiColor: AppTheme.Palette.canvas))
        .foregroundStyle(Color(uiColor: AppTheme.Palette.text))
        .tint(Color(uiColor: AppTheme.Palette.accent))
        .task { await load() }.refreshable { await load() }
    }

    private func load() async {
        guard !loading else { return }
        let stamp = session.capture()
        if defect == nil { defect = repository.cachedDefect(projectCode: projectCode, id: defectID) }
        loading = true
        errorMessage = nil
        defer { loading = false }
        do {
            let result = try await repository.defect(projectCode: projectCode, id: defectID)
            guard session.isCurrent(stamp), !Task.isCancelled else { return }
            defect = result
            usingCache = false
        } catch {
            guard session.isCurrent(stamp), !Task.isCancelled, !(error is CancellationError) else { return }
            errorMessage = "Could not load defect".localized
            usingCache = defect != nil
        }
    }
}

struct WorkHomeView: View {
    @ObservedObject var selection: SelectedProjectStore
    let onRuns: () -> Void
    let onDefects: () -> Void
    let onSelectProject: (ProjectSummary) -> Void
    let onManageProjects: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Space.section) {
                ProjectTitlePicker(
                    selection: selection,
                    onSelect: onSelectProject,
                    onManage: onManageProjects,
                    style: .compact
                )
                VStack(spacing: 0) {
                    EntityRow(identifier: "", title: "Runs".localized, symbol: "play.circle", action: onRuns)
                    Divider().padding(.leading, AppTheme.Space.regular)
                    EntityRow(
                        identifier: "",
                        title: "Defects".localized,
                        symbol: "ladybug",
                        action: onDefects
                    )
                }
                .background(
                    Color(uiColor: AppTheme.Palette.surface),
                    in: RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                )
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .stroke(Color(uiColor: AppTheme.Palette.border)))
            }.frame(maxWidth: AppTheme.Size.content).padding(AppTheme.Space.screen).frame(maxWidth: .infinity)
        }.background(Color(uiColor: AppTheme.Palette.canvas))
            .foregroundStyle(Color(uiColor: AppTheme.Palette.text))
            .tint(Color(uiColor: AppTheme.Palette.accent))
    }
}
