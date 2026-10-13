import Foundation

@MainActor
final class SuiteCatalogLoader {
    private let repository: HomeRepository
    private let dao: RealmManager
    private let session: SessionContext
    private let stamp: SessionStamp
    private let pageSize = 50

    init(network: NetworkManager, dao: RealmManager, session: SessionContext) {
        repository = HomeRepository(network: network, session: session)
        self.dao = dao
        self.session = session
        stamp = session.capture()
    }

    func load(projectCode: String, isCurrent: @MainActor () -> Bool) async throws -> [TestListEntity] {
        var values: [TestListEntity] = []
        var seen = Set<Int>()
        var offset = 0
        while true {
            guard accepts(isCurrent) else { throw CancellationError() }
            let page = try await repository.suites(projectCode: projectCode, offset: offset)
            guard accepts(isCurrent) else { throw CancellationError() }
            let newValues = page.entities.filter { seen.insert($0.id).inserted }
            values.append(contentsOf: newValues)
            offset += page.entities.count
            let total = page.filtered ?? page.total
            let finished = page.entities
                .isEmpty || (total.map { offset >= $0 } ?? (page.entities.count < pageSize))
            if finished { break }
            guard !newValues.isEmpty
            else { throw API.NetError.invalidRequest("The suite catalog did not advance") }
        }
        guard accepts(isCurrent) else { throw CancellationError() }
        guard dao.replaceSuiteCatalog(values, projectCode: projectCode, stamp: stamp) else {
            throw API.NetError.invalidRequest("The suite catalog could not be saved")
        }
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

    static func pathTitle(catalog: [TestListEntity], suiteID: Int?) -> String {
        breadcrumbs(catalog: catalog, suiteID: suiteID)?.map(\.title).joined(separator: " › ") ?? "Path unavailable"
            .localized
    }
}
