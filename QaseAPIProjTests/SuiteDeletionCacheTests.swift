import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

@Suite(.timeLimit(.minutes(1))) @MainActor
struct SuiteDeletionCacheTests {
    private func suite(_ id: Int, parent: Int?) -> TestListEntity {
        TestListEntity(
            isSuite: true,
            id: id,
            title: "Suite \(id)",
            description: nil,
            parentId: parent,
            casesCount: 1
        )
    }

    private func caseRow(_ id: Int, in suiteID: Int) -> TestListEntity {
        TestListEntity(
            isSuite: false,
            id: id,
            title: "Case \(id)",
            description: nil,
            parentId: suiteID,
            casesCount: nil
        )
    }

    private func detail(_ id: Int, suiteID: Int?, project: String, owner: String) throws -> TestCaseEntity {
        let fixture = TestEntityRO(
            testCaseData: .empty,
            reference: TestCaseReference(projectCode: project, caseID: id),
            ownerID: owner
        )
        fixture.id = id
        guard var value = TestCaseEntity(realmObject: fixture) else { throw CocoaError(.fileReadUnknown) }
        value.suiteId = suiteID
        return value
    }

    /// Набор 1 (родитель nil) → вложенный 2; набор 3 отдельно. Кейсы 10 (в 1), 11 (в 2), 12 (в 3).
    private func populate(_ dao: RealmManager, session: SessionContext, project: String) throws {
        let owner = try #require(session.ownerID)
        let stamp = session.capture()
        #expect(dao.replaceSuiteCatalog(
            [suite(1, parent: nil), suite(2, parent: 1), suite(3, parent: nil)],
            projectCode: project,
            stamp: stamp
        ))
        for (suiteID, caseID) in [(1, 10), (2, 11), (3, 12)] {
            #expect(dao.replaceRepositoryCases(
                [caseRow(caseID, in: suiteID)],
                snapshot: .init(caseIDs: [caseID], updatedAt: Date(timeIntervalSince1970: 100)),
                location: .init(projectCode: project, suiteID: suiteID),
                stamp: stamp
            ))
            let reference = TestCaseReference(projectCode: project, caseID: caseID)
            let value = try detail(caseID, suiteID: suiteID, project: project, owner: owner)
            #expect(dao.saveTestCase(value, reference: reference, stamp: stamp))
        }
        for caseID in [10, 12] {
            let item = RecentCaseItem(
                reference: TestCaseReference(projectCode: project, caseID: caseID),
                title: "Case \(caseID)",
                description: nil,
                priority: nil,
                automation: nil,
                viewedAt: Date(timeIntervalSince1970: Double(caseID))
            )
            #expect(dao.recordRecentCase(item, stamp: stamp))
        }
    }

    private func suiteIDs(_ dao: RealmManager, _ project: String) -> Set<Int> {
        Set(dao.getAllCachedSuites(projectCode: project).map(\.id))
    }

    private func caseIDs(_ dao: RealmManager, _ project: String) -> Set<Int> {
        Set(dao.getAllCachedCases(projectCode: project).map(\.id))
    }

    private func detailIDs(_ dao: RealmManager, _ project: String) -> Set<Int> {
        Set([10, 11, 12].filter {
            dao.getTestCase(reference: TestCaseReference(projectCode: project, caseID: $0)) != nil
        })
    }

    @Test func deletingSuiteRemovesSubtreeAndKeepsOtherSuitesAndOwners() throws {
        let session = SessionContext(ownerID: "other-owner")
        let dao = TestDependencies.cache(session: session)
        try populate(dao, session: session, project: "A")

        session.invalidate()
        session.activate(ownerID: "owner")
        try populate(dao, session: session, project: "A")
        try populate(dao, session: session, project: "B")

        let root = suite(1, parent: nil)
        #expect(dao.deleteEntity(root, projectCode: "A", stamp: session.capture()))

        #expect(suiteIDs(dao, "A") == [3])
        #expect(caseIDs(dao, "A") == [12])
        #expect(detailIDs(dao, "A") == [12])
        #expect(Set(dao.getRecentCases(projectCode: "A").map(\.reference.caseID)) == [12])
        #expect(dao.repositorySnapshot(location: .init(projectCode: "A", suiteID: 1)) == nil)
        #expect(dao.repositorySnapshot(location: .init(projectCode: "A", suiteID: 2)) == nil)
        #expect(dao.repositorySnapshot(location: .init(projectCode: "A", suiteID: 3)) != nil)

        #expect(suiteIDs(dao, "B") == [1, 2, 3])
        #expect(caseIDs(dao, "B") == [10, 11, 12])
        #expect(detailIDs(dao, "B") == [10, 11, 12])
        #expect(Set(dao.getRecentCases(projectCode: "B").map(\.reference.caseID)) == [10, 12])

        session.invalidate()
        session.activate(ownerID: "other-owner")
        #expect(suiteIDs(dao, "A") == [1, 2, 3])
        #expect(caseIDs(dao, "A") == [10, 11, 12])
        #expect(detailIDs(dao, "A") == [10, 11, 12])
        #expect(Set(dao.getRecentCases(projectCode: "A").map(\.reference.caseID)) == [10, 12])
        #expect(dao.repositorySnapshot(location: .init(projectCode: "A", suiteID: 1)) != nil)
    }

    @Test func deletingNestedSuiteKeepsParentAndItsCases() throws {
        let session = SessionContext(ownerID: "owner")
        let dao = TestDependencies.cache(session: session)
        try populate(dao, session: session, project: "A")

        #expect(dao.deleteEntity(suite(2, parent: 1), projectCode: "A", stamp: session.capture()))

        #expect(suiteIDs(dao, "A") == [1, 3])
        #expect(caseIDs(dao, "A") == [10, 12])
        #expect(detailIDs(dao, "A") == [10, 12])
        #expect(dao.repositorySnapshot(location: .init(projectCode: "A", suiteID: 2)) == nil)
        #expect(dao.repositorySnapshot(location: .init(projectCode: "A", suiteID: 1)) != nil)
    }

    @Test func deletingSuiteRemovesCaseDetailsThatHaveNoCachedListRow() throws {
        let session = SessionContext(ownerID: "owner")
        let dao = TestDependencies.cache(session: session)
        let stamp = session.capture()
        #expect(dao.replaceSuiteCatalog([suite(1, parent: nil)], projectCode: "A", stamp: stamp))
        let reference = TestCaseReference(projectCode: "A", caseID: 10)
        let value = try detail(10, suiteID: 1, project: "A", owner: "owner")
        #expect(dao.saveTestCase(value, reference: reference, stamp: stamp))

        #expect(dao.deleteEntity(suite(1, parent: nil), projectCode: "A", stamp: session.capture()))

        #expect(dao.getTestCase(reference: reference) == nil)
    }

    private func counted(_ id: Int, parent: Int?, cases: Int?) -> TestListEntity {
        TestListEntity(
            isSuite: true,
            id: id,
            title: "Suite \(id)",
            description: nil,
            parentId: parent,
            casesCount: cases
        )
    }

    @Test func subtreeCountSumsDescendantsOfParentWithoutDirectCases() {
        let catalog = [
            counted(1, parent: nil, cases: 0),
            counted(2, parent: 1, cases: 3),
            counted(3, parent: 1, cases: 4),
            counted(4, parent: nil, cases: 100)
        ]
        #expect(TestEntitiesViewModel.casesCount(inSubtreeOf: 1, catalog: catalog) == 7)
        #expect(TestEntitiesViewModel.casesCount(inSubtreeOf: 2, catalog: catalog) == 3)
    }

    @Test func subtreeCountIsUnknownWhenAnyNodeHasNoCount() {
        let catalog = [
            counted(1, parent: nil, cases: 0),
            counted(2, parent: 1, cases: 3),
            counted(3, parent: 1, cases: nil)
        ]
        #expect(TestEntitiesViewModel.casesCount(inSubtreeOf: 1, catalog: catalog) == nil)
        #expect(TestEntitiesViewModel.casesCount(inSubtreeOf: 2, catalog: catalog) == 3)
        #expect(TestEntitiesViewModel.casesCount(inSubtreeOf: 99, catalog: catalog) == nil)
    }

    @Test func subtreeCountSurvivesParentCycle() {
        let catalog = [counted(1, parent: 2, cases: 1), counted(2, parent: 1, cases: 2)]
        #expect(TestEntitiesViewModel.casesCount(inSubtreeOf: 1, catalog: catalog) == 3)
    }

    @Test func subtreeIDsTreatZeroParentAsRootAndSurviveCycles() {
        let catalog = [
            counted(1, parent: 0, cases: 1),
            counted(2, parent: 1, cases: 1),
            counted(3, parent: 2, cases: 1),
            counted(4, parent: 0, cases: 1)
        ]
        #expect(SuiteCatalogLoader.subtreeIDs(of: 1, in: catalog) == [1, 2, 3])
        #expect(SuiteCatalogLoader.subtreeIDs(of: 2, in: catalog) == [2, 3])
        #expect(SuiteCatalogLoader.subtreeIDs(of: 99, in: catalog) == [99])

        let cyclic = [counted(1, parent: 2, cases: 1), counted(2, parent: 1, cases: 1)]
        #expect(SuiteCatalogLoader.subtreeIDs(of: 1, in: cyclic) == [1, 2])
    }

    @Test func subtreeCountTreatsZeroParentAsRoot() {
        let catalog = [
            counted(1, parent: 0, cases: 0),
            counted(2, parent: 1, cases: 3),
            counted(3, parent: 1, cases: 4),
            counted(4, parent: 0, cases: 100)
        ]
        #expect(TestEntitiesViewModel.casesCount(inSubtreeOf: 1, catalog: catalog) == 7)
    }

    @Test func modelReportsSubtreeCountOnlyForCompleteCatalog() {
        let session = SessionContext(ownerID: "owner")
        let dao = TestDependencies.cache(session: session)
        let incomplete = TestDependencies.entities(projectCode: "A", dao: dao, session: session)
        #expect(incomplete.casesCountInSubtree(of: 1) == nil)

        #expect(dao.replaceSuiteCatalog(
            [
                counted(1, parent: nil, cases: 0),
                counted(2, parent: 1, cases: 3),
                counted(3, parent: 1, cases: 4)
            ],
            projectCode: "A",
            stamp: session.capture()
        ))
        let complete = TestDependencies.entities(projectCode: "A", dao: dao, session: session)
        #expect(complete.casesCountInSubtree(of: 1) == 7)
    }
}

// MARK: - Каскад удаления проекта и кейса (DC-5)

private struct ProjectRows: Equatable {
    var projects = 0
    var entities = 0
    var details = 0
    var reads = 0
    var homes = 0
    var recents = 0
}

/// Проект после `seedProject`: сводка; 3 набора + 3 кейса в списках; 3 детали; 5 записей `ReadCacheRO`
/// (каталог наборов, 3 снимка уровней, список запусков); снимок Home; 2 недавних кейса.
private let seededRows = ProjectRows(projects: 1, entities: 6, details: 3, reads: 5, homes: 1, recents: 2)
/// Шаги `seedProject`: у каждой из 3 деталей корневой шаг и один вложенный.
private let seededStepsPerProject = 6

extension SuiteDeletionCacheTests {
    private func makeStore(owner: String) -> (session: SessionContext, dao: RealmManager, realm: Realm?) {
        let configuration = Realm.Configuration(
            inMemoryIdentifier: UUID().uuidString,
            objectTypes: RealmManager.cacheObjectTypes
        )
        let session = SessionContext(ownerID: owner)
        let dao = RealmManager(configuration: configuration, session: session)
        // Сильная ссылка удерживает in-memory хранилище, а тест читает сырые строки и шаги.
        return (session, dao, try? Realm(configuration: configuration))
    }

    private func rows(_ realm: Realm, owner: String, project: String) -> ProjectRows {
        func count<T: Object>(_ type: T.Type, field: String) -> Int {
            realm.objects(type).filter("ownerID == %@ AND \(field) == %@", owner, project).count
        }
        return ProjectRows(
            projects: count(ProjectRO.self, field: "code"),
            entities: count(TestEntitiesDataRO.self, field: "codeOfProject"),
            details: count(TestEntityRO.self, field: "projectCode"),
            reads: count(ReadCacheRO.self, field: "projectCode"),
            homes: count(HomeSnapshotRO.self, field: "projectCode"),
            recents: count(RecentCaseRO.self, field: "projectCode")
        )
    }

    private func stepCount(_ realm: Realm) -> Int { realm.objects(StepsInTestCaseRO.self).count }

    private func nestedSteps() -> [StepsInTestCase] {
        let child = StepsInTestCase(
            hash: "child",
            position: 1,
            sharedStepHash: nil,
            sharedStepNestedHash: nil,
            attachments: [],
            action: "Child",
            expectedResult: nil,
            data: nil,
            steps: []
        )
        return [StepsInTestCase(
            hash: "root",
            position: 1,
            sharedStepHash: nil,
            sharedStepNestedHash: nil,
            attachments: [],
            action: "Root",
            expectedResult: nil,
            data: nil,
            steps: [child]
        )]
    }

    /// Заполняет проект всеми видами строк, которые должен убирать каскад (см. `seededRows`).
    private func seedProject(_ dao: RealmManager, session: SessionContext, code: String) throws {
        try populate(dao, session: session, project: code)
        let owner = try #require(session.ownerID)
        let stamp = session.capture()
        let summary = ProjectSummary(title: "Project \(code)", code: code)
        #expect(dao.saveProjectSummaries([summary], stamp: stamp))
        let home = HomeSnapshot(projectCode: code, activeRun: nil, metricsUpdatedAt: nil, runUpdatedAt: nil)
        #expect(dao.saveHomeSnapshot(home, stamp: stamp))
        #expect(dao.saveRuns([RunReadDTO(id: 1, title: "Run")], projectCode: code, stamp: stamp))
        for (suiteID, caseID) in [(1, 10), (2, 11), (3, 12)] {
            var value = try detail(caseID, suiteID: suiteID, project: code, owner: owner)
            value.steps = nestedSteps()
            let reference = TestCaseReference(projectCode: code, caseID: caseID)
            #expect(dao.saveTestCase(value, reference: reference, stamp: stamp))
        }
    }

    /// Проекты A и B владельца `owner` и проект A владельца `other-owner`, все в одном хранилище.
    private func seedTwoOwners() throws -> (session: SessionContext, dao: RealmManager, realm: Realm) {
        let store = makeStore(owner: "other-owner")
        let realm = try #require(store.realm)
        try seedProject(store.dao, session: store.session, code: "A")
        store.session.invalidate()
        store.session.activate(ownerID: "owner")
        try seedProject(store.dao, session: store.session, code: "A")
        try seedProject(store.dao, session: store.session, code: "B")
        #expect(rows(realm, owner: "owner", project: "A") == seededRows)
        #expect(rows(realm, owner: "owner", project: "B") == seededRows)
        #expect(rows(realm, owner: "other-owner", project: "A") == seededRows)
        #expect(stepCount(realm) == 3 * seededStepsPerProject)
        return (store.session, store.dao, realm)
    }

    /// Ловит: пропуск любого из шести удалений в `deleteProject` (сводка, списки, детали, `ReadCacheRO`,
    /// Home, недавние), рекурсии по шагам (`deleteSteps`) и потерю фильтра по владельцу или коду.
    @Test func deleteProjectRemovesItsCacheOnlyForThatProjectAndOwner() throws {
        let (session, dao, realm) = try seedTwoOwners()
        var project = Project()
        project.code = "A"

        #expect(dao.deleteProject(project, stamp: session.capture()))

        #expect(rows(realm, owner: "owner", project: "A") == ProjectRows())
        #expect(rows(realm, owner: "owner", project: "B") == seededRows)
        #expect(rows(realm, owner: "other-owner", project: "A") == seededRows)
        #expect(stepCount(realm) == 2 * seededStepsPerProject)
        #expect(dao.getProjectSummaries().map(\.code) == ["B"])
    }

    /// Ловит: пропуск любого удаления в каскаде `replaceProjectSummaries` для проекта, пропавшего из ответа,
    /// и потерю фильтра по владельцу или коду.
    @Test func replacingSummariesCascadesOnlyForProjectsMissingFromTheResponse() throws {
        let (session, dao, realm) = try seedTwoOwners()

        #expect(dao.replaceProjectSummaries(
            [ProjectSummary(title: "Project B", code: "B")],
            stamp: session.capture()
        ))

        #expect(rows(realm, owner: "owner", project: "A") == ProjectRows())
        #expect(rows(realm, owner: "owner", project: "B") == seededRows)
        #expect(rows(realm, owner: "other-owner", project: "A") == seededRows)
        #expect(stepCount(realm) == 2 * seededStepsPerProject)
        #expect(dao.getProjectSummaries().map(\.code) == ["B"])
    }

    /// Ловит: `deleteEntity` для кейса не удаляет строку списка (ключ `case`), детали с шагами
    /// или недавнюю запись; либо задевает другой проект и владельца.
    @Test func deletingCaseRemovesRowDetailStepsAndRecentOnly() throws {
        let (session, dao, realm) = try seedTwoOwners()

        #expect(dao.deleteEntity(caseRow(10, in: 1), projectCode: "A", stamp: session.capture()))

        #expect(caseIDs(dao, "A") == [11, 12])
        #expect(detailIDs(dao, "A") == [11, 12])
        #expect(suiteIDs(dao, "A") == [1, 2, 3])
        #expect(Set(dao.getRecentCases(projectCode: "A").map(\.reference.caseID)) == [12])
        #expect(stepCount(realm) == 3 * seededStepsPerProject - 2)
        #expect(rows(realm, owner: "owner", project: "B") == seededRows)
        #expect(rows(realm, owner: "other-owner", project: "A") == seededRows)
    }

    /// Ловит: удаление деталей кейса только при наличии строки в списке (деталь без строки остаётся).
    @Test func deletingCaseRemovesDetailThatHasNoListRow() throws {
        let store = makeStore(owner: "owner")
        let realm = try #require(store.realm)
        var value = try detail(10, suiteID: 1, project: "A", owner: "owner")
        value.steps = nestedSteps()
        let reference = TestCaseReference(projectCode: "A", caseID: 10)
        #expect(store.dao.saveTestCase(value, reference: reference, stamp: store.session.capture()))
        #expect(stepCount(realm) == 2)

        #expect(store.dao.deleteEntity(
            caseRow(10, in: 1),
            projectCode: "A",
            stamp: store.session.capture()
        ))

        #expect(store.dao.getTestCase(reference: reference) == nil)
        #expect(stepCount(realm) == 0)
    }
}

// MARK: - TestEntitiesViewModel.delete (DC-6)

/// Сеть для сценариев удаления и отказа кеша: ответ на удаление задаёт `deleteStatus`, чтения уровня можно
/// сломать (`levelsFail`), чтобы перезапрос не переписал кеш. `reload()` шлёт запросы уровня параллельно,
/// поэтому состояние на MainActor; методы протокола `nonisolated`, чтобы `T.Type` не пересекал границу акторов.
@MainActor
final class RepositoryScriptNetwork: NetworkManager {
    struct Call: Equatable {
        let operation: API.Operation
        let path: [String: String]
    }

    var deleteStatus = true
    var levelsFail = false
    private(set) var calls: [Call] = []
    var deletes: [Call] { calls.filter { $0.operation == .deleteSuite || $0.operation == .deleteCase } }

    nonisolated func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem],
        with data: Encodable?,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        let body = try await respond(operation: operation, path: pathParameters)
        return try API.decodeResponse(from: Data(body.utf8), as: modelType)
    }

    /// Регистрирует вызов и возвращает тело ответа по текущим настройкам.
    private func respond(operation: API.Operation, path: [String: String]) throws(API.NetError) -> String {
        calls.append(Call(operation: operation, path: path))
        let emptyPage = #"{"status":true,"result":{"total":0,"filtered":0,"count":0,"entities":[]}}"#
        let runsPage = #"{"total":1,"count":1,"entities":[{"id":1,"title":"Run 1"}]}"#
        let body: String
        switch operation {
        case .deleteSuite, .deleteCase:
            body = #"{"status":\#(deleteStatus)}"#
        case .getSuites, .getCases:
            if levelsFail { throw .noInternetConnection }
            body = emptyPage
        case .getProject:
            body = #"{"status":true,"result":{"title":"A","code":"A"}}"#
        case .getRuns:
            body = #"{"status":true,"result":\#(runsPage)}"#
        default:
            throw .invalidRequest("Unexpected operation \(operation.rawValue)")
        }
        return body
    }

    nonisolated func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .invalidURL }

    nonisolated func auth(by token: String) async throws -> Bool { true }
}

extension SuiteDeletionCacheTests {
    private func thrownError(_ body: () async throws -> Void) async -> Error? {
        do { try await body(); return nil } catch { return error }
    }

    private func deletionModel(
        network: RepositoryScriptNetwork,
        session: SessionContext
    ) throws -> (model: TestEntitiesViewModel, dao: RealmManager) {
        let dao = TestDependencies.cache(session: session)
        try populate(dao, session: session, project: "A")
        let model = TestDependencies.entities(projectCode: "A", network: network, dao: dao, session: session)
        return (model, dao)
    }

    /// Ловит: перепутать операции (`.deleteCase` для набора) или потерять `code`/`id` в пути.
    @Test func deletingSuiteSendsDeleteSuiteWithProjectCodeAndID() async throws {
        let network = RepositoryScriptNetwork()
        let (model, _) = try deletionModel(network: network, session: SessionContext(ownerID: "owner"))

        try await model.delete(RepositoryItemReference(projectCode: "A", id: 1, isSuite: true))

        let expected = RepositoryScriptNetwork.Call(operation: .deleteSuite, path: ["code": "A", "id": "1"])
        #expect(network.deletes == [expected])
    }

    /// Ловит: перепутать операции (`.deleteSuite` для кейса) или потерять `code`/`id` в пути.
    @Test func deletingCaseSendsDeleteCaseWithProjectCodeAndID() async throws {
        let network = RepositoryScriptNetwork()
        let (model, _) = try deletionModel(network: network, session: SessionContext(ownerID: "owner"))

        try await model.delete(RepositoryItemReference(projectCode: "A", id: 10, isSuite: false))

        let expected = RepositoryScriptNetwork.Call(operation: .deleteCase, path: ["code": "A", "id": "10"])
        #expect(network.deletes == [expected])
    }

    /// Ловит: убрать проверку `response.status` — кеш чистился бы и список перезапрашивался после отказа.
    @Test(arguments: [true, false])
    func rejectedDeleteResponseThrowsAndKeepsCacheWithoutReload(isSuite: Bool) async throws {
        let network = RepositoryScriptNetwork()
        network.deleteStatus = false
        let (model, dao) = try deletionModel(network: network, session: SessionContext(ownerID: "owner"))
        let reference = RepositoryItemReference(projectCode: "A", id: isSuite ? 1 : 10, isSuite: isSuite)

        let error = await thrownError { try await model.delete(reference) }

        guard case .invalidRequest(let message)? = error as? API.NetError else {
            Issue.record("Ожидалась invalidRequest, получено \(String(describing: error))")
            return
        }
        #expect(message == "Delete failed")
        let expected: API.Operation = isSuite ? .deleteSuite : .deleteCase
        #expect(network.calls.map(\.operation) == [expected])
        #expect(suiteIDs(dao, "A") == [1, 2, 3])
        #expect(caseIDs(dao, "A") == [10, 11, 12])
        #expect(detailIDs(dao, "A") == [10, 11, 12])
    }

    /// Ловит: убрать сверку `reference.projectCode == projectCode` — удаление ушло бы в чужой проект.
    @Test func deletingReferenceOfAnotherProjectIsCancelledWithoutRequest() async throws {
        let network = RepositoryScriptNetwork()
        let (model, dao) = try deletionModel(network: network, session: SessionContext(ownerID: "owner"))

        let error = await thrownError {
            try await model.delete(RepositoryItemReference(projectCode: "B", id: 1, isSuite: true))
        }

        #expect(error is CancellationError)
        #expect(network.calls.isEmpty)
        #expect(suiteIDs(dao, "A") == [1, 2, 3])
    }

    /// Ловит: убрать проверку сессии перед запросом — устаревшая модель удаляла бы данные нового владельца.
    @Test func deletingAfterSessionInvalidationIsCancelledWithoutRequest() async throws {
        let session = SessionContext(ownerID: "owner")
        let network = RepositoryScriptNetwork()
        let (model, _) = try deletionModel(network: network, session: session)
        session.invalidate()

        let error = await thrownError {
            try await model.delete(RepositoryItemReference(projectCode: "A", id: 1, isSuite: true))
        }

        #expect(error is CancellationError)
        #expect(network.calls.isEmpty)
    }

    /// Ловит: убрать `dao.deleteEntity` в `delete`. Перезапрос уровня сломан: иначе `reload()` сам
    /// переписал бы кеш и тест не заметил бы пропуск удаления.
    @Test func deletingSuiteRemovesSubtreeFromCacheEvenWhenLevelReloadFails() async throws {
        let network = RepositoryScriptNetwork()
        network.levelsFail = true
        let (model, dao) = try deletionModel(network: network, session: SessionContext(ownerID: "owner"))

        try await model.delete(RepositoryItemReference(projectCode: "A", id: 1, isSuite: true))

        #expect(model.suiteError != nil && model.caseError != nil)
        #expect(suiteIDs(dao, "A") == [3])
        #expect(caseIDs(dao, "A") == [12])
        #expect(detailIDs(dao, "A") == [12])
    }

    /// Ловит: убрать `dao.deleteEntity` в `delete` для кейса (строка и деталь остаются в кеше).
    @Test func deletingCaseRemovesRowAndDetailFromCacheEvenWhenLevelReloadFails() async throws {
        let network = RepositoryScriptNetwork()
        network.levelsFail = true
        let (model, dao) = try deletionModel(network: network, session: SessionContext(ownerID: "owner"))

        try await model.delete(RepositoryItemReference(projectCode: "A", id: 10, isSuite: false))

        #expect(model.suiteError != nil && model.caseError != nil)
        #expect(suiteIDs(dao, "A") == [1, 2, 3])
        #expect(caseIDs(dao, "A") == [11, 12])
        #expect(detailIDs(dao, "A") == [11, 12])
    }
}
