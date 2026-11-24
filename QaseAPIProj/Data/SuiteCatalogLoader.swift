import Foundation

@MainActor
final class SuiteCatalogLoader: SuiteCatalogLoading {
    private let repository: RepositoryReading
    private let dao: RepositoryCaching
    private let session: SessionContext
    private let stamp: SessionStamp
    private let onCacheFailure: () -> Void

    init(
        repository: RepositoryReading,
        dao: RepositoryCaching,
        session: SessionContext,
        onCacheFailure: @escaping () -> Void = {}
    ) {
        self.repository = repository
        self.dao = dao
        self.session = session
        self.onCacheFailure = onCacheFailure
        stamp = session.capture()
    }

    func load(projectCode: String, isCurrent: @MainActor () -> Bool) async throws -> [TestListEntity] {
        var values: [TestListEntity] = []
        var seen = Set<Int>()
        var offset = 0
        while true {
            guard accepts(isCurrent) else { throw CancellationError() }
            let page = try await repository.suites(projectCode: projectCode, query: "", offset: offset)
            guard accepts(isCurrent) else { throw CancellationError() }
            let newValues = page.entities.filter { seen.insert($0.id).inserted }
            values.append(contentsOf: newValues)
            offset += page.entities.count
            guard page.entities.isEmpty || !newValues.isEmpty else {
                throw API.NetError.invalidRequest("The suite catalog did not advance")
            }
            if !PaginationPolicy.hasMore(
                received: page.entities.count,
                offset: offset,
                total: page.filtered ?? page.total
            ) { break }
        }
        guard accepts(isCurrent) else { throw CancellationError() }
        // Каталог получен из сети целиком: отказ записи в кеш сообщается отдельно и не отбрасывает данные.
        if !dao.replaceSuiteCatalog(values, projectCode: projectCode, stamp: stamp) { onCacheFailure() }
        guard accepts(isCurrent) else { throw CancellationError() }
        return values
    }

    private func accepts(_ isCurrent: @MainActor () -> Bool) -> Bool {
        isCurrent() && session.isCurrent(stamp) && !Task.isCancelled
    }

    static func breadcrumbs(catalog: [TestListEntity], suiteID: Int?) -> [RepositoryBreadcrumb]? {
        let byID = Dictionary(catalog.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var result: [RepositoryBreadcrumb] = []
        var next = suiteID == 0 ? nil : suiteID
        var seen = Set<Int>()
        while let id = next {
            guard seen.insert(id).inserted, let suite = byID[id] else { return nil }
            result.append(.init(id: id, title: suite.title))
            next = suite.parentId == 0 ? nil : suite.parentId
        }
        return [.init(id: nil, title: "Project root".localized)] + result.reversed()
    }

    /// Идентификаторы набора и всех вложенных наборов. Родитель `0` равен корню проекта; циклы безопасны.
    static func subtreeIDs(of rootID: Int, in suites: [TestListEntity]) -> Set<Int> {
        var childrenByParent: [Int: [Int]] = [:]
        for suite in suites where suite.isSuite {
            guard let parent = suite.parentId, parent != 0 else { continue }
            childrenByParent[parent, default: []].append(suite.id)
        }
        var visited: Set<Int> = [rootID]
        var pending = [rootID]
        while let next = pending.popLast() {
            for child in childrenByParent[next] ?? [] where visited.insert(child).inserted {
                pending.append(child)
            }
        }
        return visited
    }

    static func pathTitle(catalog: [TestListEntity], suiteID: Int?) -> String {
        breadcrumbs(catalog: catalog, suiteID: suiteID)?.map(\.title).joined(separator: " › ")
            ?? "Path unavailable".localized
    }
}
