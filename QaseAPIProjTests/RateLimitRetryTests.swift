import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

/// Чтение через `HomeRepository` переживает одиночный 429: один повтор после `Retry-After` до 10 с.
@Suite(.timeLimit(.minutes(1))) @MainActor
struct RateLimitRetryTests {
    @Test func rateLimitedPageIsRetriedOnceAfterRetryAfter() async throws {
        let fixture = RetryFixture([.rateLimited(retryAfter: 2), .runs([1])])
        let page = try await fixture.repository.runs(projectCode: "A", offset: 0)
        #expect(page.entities.map(\.id) == [1])
        #expect(fixture.network.calls == 2)
        #expect(fixture.sleeps == [.seconds(2)])
    }

    @Test func missingRetryAfterWaitsDefaultDelay() async throws {
        let fixture = RetryFixture([.rateLimited(retryAfter: nil), .runs([1])])
        _ = try await fixture.repository.runs(projectCode: "A", offset: 0)
        #expect(fixture.sleeps == [.seconds(1)])
    }

    @Test func negativeRetryAfterDoesNotProduceNegativeWait() async throws {
        let fixture = RetryFixture([.rateLimited(retryAfter: -5), .runs([1])])
        _ = try await fixture.repository.runs(projectCode: "A", offset: 0)
        #expect(fixture.sleeps == [.seconds(0)])
    }

    @Test func longRetryAfterFailsWithoutWaiting() async {
        let fixture = RetryFixture([.rateLimited(retryAfter: 30), .runs([1])])
        await #expect(throws: API.NetError.self) {
            try await fixture.repository.runs(projectCode: "A", offset: 0)
        }
        #expect(fixture.network.calls == 1)
        #expect(fixture.sleeps.isEmpty)
    }

    @Test func secondRateLimitIsReportedToCaller() async {
        let fixture = RetryFixture([.rateLimited(retryAfter: 1), .rateLimited(retryAfter: 1), .runs([1])])
        do {
            _ = try await fixture.repository.runs(projectCode: "A", offset: 0)
            Issue.record("A second 429 must fail the request")
        } catch API.NetError.httpError(statusCode: let status, message: _, retryAfter: _) {
            #expect(status == 429)
        } catch {
            Issue.record("Unexpected error \(error)")
        }
        #expect(fixture.network.calls == 2)
    }

    @Test func sessionChangeDuringWaitCancelsRetryAndCacheWrite() async {
        let fixture = RetryFixture([.rateLimited(retryAfter: 1), .runs([1])])
        fixture.onSleep = { fixture.session.activate(ownerID: "other") }
        await #expect(throws: CancellationError.self) {
            try await fixture.repository.runs(projectCode: "A", offset: 0)
        }
        #expect(fixture.network.calls == 1)
        fixture.session.activate(ownerID: "owner")
        #expect(fixture.dao.getRuns(projectCode: "A") == nil)
    }

    @Test func cancellationDuringWaitPreventsRetry() async {
        let fixture = RetryFixture([.rateLimited(retryAfter: 1), .runs([1])])
        // Подменённое ожидание при отмене не бросает (в отличие от `Task.sleep`): проверка после ожидания обязательна.
        var load: Task<QaseAPIListResult<RunReadDTO>, Error>?
        fixture.onSleep = { load?.cancel() }
        load = Task { try await fixture.repository.runs(projectCode: "A", offset: 0) }
        let result = await load?.result
        if case .failure(let error)? = result {
            #expect(error is CancellationError)
        } else {
            Issue.record("Cancelled wait must not retry the request")
        }
        #expect(fixture.network.calls == 1)
    }

    @Test func projectTraversalSurvivesRateLimitOnSecondPage() async {
        let fixture = RetryFixture([
            .projects(["A"], total: 2),
            .rateLimited(retryAfter: 1),
            .projects(["B"], total: 2)
        ])
        let store = SelectedProjectStore(
            repository: fixture.repository,
            cache: fixture.dao,
            session: fixture.session,
            defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard
        )
        await store.load()
        #expect(store.projects.map(\.code) == ["A", "B"])
        #expect(store.errorMessage == nil)
        #expect(fixture.network.calls == 3)
    }
}

@MainActor
private final class RetryFixture {
    let session = SessionContext(ownerID: "owner")
    let network: ScriptedHomeNetwork
    let dao: RealmManager
    private(set) var sleeps: [Duration] = []
    var onSleep: () -> Void = {}
    private(set) var repository: HomeRepository!

    init(_ replies: [ScriptedHomeNetwork.Reply]) {
        network = ScriptedHomeNetwork(replies)
        dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        repository = HomeRepository(
            network: network,
            dao: dao,
            session: session,
            sleep: { [unowned self] duration in
                sleeps.append(duration)
                onSleep()
            }
        )
    }
}

/// N-й запрос получает `replies[N-1]`: страницу запусков, страницу проектов или 429.
/// Без `@MainActor`: вызовы строго последовательны, приостановки нет.
private final class ScriptedHomeNetwork: NetworkManager {
    enum Reply {
        case runs([Int])
        case projects([String], total: Int)
        case rateLimited(retryAfter: TimeInterval?)
    }

    private let replies: [Reply]
    private(set) var calls = 0

    init(_ replies: [Reply]) { self.replies = replies }

    func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem],
        with data: Encodable?,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        calls += 1
        guard calls <= replies.count else { throw .invalidRequest("Unexpected request #\(calls)") }
        let result: String
        switch replies[calls - 1] {
        case .rateLimited(let retryAfter):
            throw .httpError(statusCode: 429, message: "Rate limit", retryAfter: retryAfter)
        case .runs(let ids):
            let entities = ids.map { #"{"id": \#($0), "title": "Run \#($0)"}"# }.joined(separator: ",")
            result = #"{"total": \#(ids.count), "entities": [\#(entities)]}"#
        case .projects(let codes, let total):
            let entities = codes.map { #"{"title": "\#($0)", "code": "\#($0)"}"# }.joined(separator: ",")
            result = #"{"total": \#(total), "entities": [\#(entities)]}"#
        }
        return try API.decodeResponse(from: Data(#"{"status": true, "result": \#(result)}"#.utf8), as: modelType)
    }

    func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .invalidURL }

    func auth(by token: String) async throws -> Bool { true }
}
