import Combine
import Foundation

@MainActor
final class PagedReadViewModel<Item: Codable & Identifiable>: ObservableObject {
    @Published private(set) var items: [Item] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var usingCache = false
    @Published private(set) var hasMore = true
    @Published var query = ""

    private let originStamp: SessionStamp
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
        originStamp = session.capture()
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
        guard !hasAppeared, session.isCurrent(originStamp), !Task.isCancelled else { return }
        hasAppeared = true
        items = cached?(query) ?? []
        await reload()
    }

    func searchChanged() {
        guard session.isCurrent(originStamp) else { return }
        generation += 1
        searchTask?.cancel()
        items = cached?(query) ?? []
        usingCache = false
        errorMessage = nil
        isLoading = false
        searchTask = Task { [weak self] in
            do { try await Task.sleep(for: SearchPolicy.debounce) }
            catch { return }
            await self?.reload()
        }
    }

    func reload() async {
        guard session.isCurrent(originStamp), !Task.isCancelled else { return }
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
            hasMore = PaginationPolicy.hasMore(
                received: page.entities.count,
                offset: nextOffset,
                total: page.filtered ?? page.total
            )
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

@MainActor
final class ReadDetailViewModel<Item>: ObservableObject {
    @Published private(set) var item: Item?
    @Published private(set) var errorMessage: String?
    @Published private(set) var loading = false
    @Published private(set) var usingCache = false
    private let session: SessionContext
    private let stamp: SessionStamp
    private let cached: () -> Item?
    private let fetch: () async throws -> Item
    private let failureMessage: String

    init(
        session: SessionContext,
        cached: @escaping () -> Item?,
        failureMessage: String,
        fetch: @escaping () async throws -> Item
    ) {
        self.session = session
        stamp = session.capture()
        self.cached = cached
        self.fetch = fetch
        self.failureMessage = failureMessage
    }

    func load() async {
        guard !loading, session.isCurrent(stamp) else { return }
        if item == nil { item = cached() }
        loading = true
        errorMessage = nil
        defer { loading = false }
        do {
            let result = try await fetch()
            guard session.isCurrent(stamp), !Task.isCancelled else { return }
            item = result
            usingCache = false
        } catch {
            guard session.isCurrent(stamp), !Task.isCancelled, !(error is CancellationError) else { return }
            errorMessage = failureMessage
            usingCache = item != nil
        }
    }
}
