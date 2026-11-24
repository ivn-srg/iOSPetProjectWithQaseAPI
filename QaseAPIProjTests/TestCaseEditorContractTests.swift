import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

private let editorReference = TestCaseReference(projectCode: "A", caseID: 7)

/// Контракт редактора с Qase: PATCH только изменённых полей, перечитывание после сохранения,
/// фоновая сверка кеша с сервером и её гонка с сохранением.
@Suite(.timeLimit(.minutes(1))) @MainActor
struct TestCaseEditorContractTests {
    // MARK: - Diff-payload

    @Test func patchBodyContainsExactlyTheKeyOfEachEditedField() async throws {
        let cases: [(FieldType, FormFieldValue, [String: Any])] = [
            (.title, .text("Renamed"), ["title": "Renamed"]),
            (.description, .text("New description"), ["description": "New description"]),
            (.precondition, .text("New precondition"), ["preconditions": "New precondition"]),
            (.postcondition, .text("New postcondition"), ["postconditions": "New postcondition"]),
            (.severity, .selection(2), ["severity": 2]),
            (.status, .selection(1), ["status": 1]),
            (.priority, .selection(1), ["priority": 1]),
            (.behavior, .selection(3), ["behavior": 3]),
            (.type, .selection(8), ["type": 8]),
            (.layer, .selection(3), ["layer": 3]),
            (.isFlaky, .toggle(true), ["is_flaky": 1]),
            (.automation, .selection(1), ["isManual": true, "isToBeAutomated": true])
        ]
        for (field, value, expected) in cases {
            let fixture = EditorFixture()
            fixture.loadEditor(with: Self.serverCase(title: "Original"))
            fixture.network.getReplies = [.success(Self.serverCase(title: "Original"))]
            fixture.model.updateValue(for: field, value: value)
            try await fixture.model.updateTestCaseData()
            let body = try #require(fixture.network.patchBodies.last, "\(field)")
            #expect(Set(body.keys) == Set(expected.keys), "\(field)")
            for (key, want) in expected {
                #expect((body[key] as? NSObject)?.isEqual(want) == true, "\(field) \(key)")
            }
        }
    }

    @Test func patchBodyOmitsStepsTagsAttachmentsAndUnchangedParent() async throws {
        let fixture = EditorFixture()
        fixture.loadEditor(with: Self.serverCase(title: "Original"))
        fixture.network.getReplies = [.success(Self.serverCase(title: "Original"))]
        fixture.model.updateValue(for: .title, value: "Renamed")
        fixture.model.updateValue(for: .priority, value: 3)
        try await fixture.model.updateTestCaseData()
        let body = try #require(fixture.network.patchBodies.last)
        #expect(Set(body.keys) == ["title", "priority"])
    }

    @Test func automationChoicesMapToIsManualPair() async throws {
        let expectations: [(Int, Bool, Bool)] = [(0, true, false), (1, true, true), (2, false, false)]
        for (automation, isManual, isToBeAutomated) in expectations {
            let fixture = EditorFixture()
            // База — автоматизация, отличная от проверяемой, чтобы поле попало в diff.
            fixture.loadEditor(with: Self.serverCase(title: "Original", automation: automation == 0 ? 2 : 0))
            fixture.network.getReplies = [.success(Self.serverCase(title: "Original"))]
            fixture.model.updateValue(for: .automation, value: automation)
            try await fixture.model.updateTestCaseData()
            let body = try #require(fixture.network.patchBodies.last)
            #expect(body["isManual"] as? Bool == isManual, "automation \(automation)")
            #expect(body["isToBeAutomated"] as? Bool == isToBeAutomated, "automation \(automation)")
            #expect(body["automation"] == nil && body["is_manual"] == nil)
        }
    }

    /// Демо-кейс DEMO/2 начинается с Manual (0); каждый шаг меняет значение, иначе сохранять нечего.
    @Test func demoMockKeepsChosenAutomationAfterSaveAndReread() async throws {
        let session = SessionContext(ownerID: "owner")
        let model = TestDependencies.detail(
            reference: .init(projectCode: "DEMO", caseID: 2),
            network: APIMockManager(),
            session: session
        )
        try await model.fetchCaseDataJSON()
        try #require(model.testCase?.automation == .manual)
        for choice: AutomationStatus in [.toBeAutomated, .automation, .manual] {
            model.updateValue(for: .automation, value: choice.apiValue)
            try await model.updateTestCaseData()
            #expect(model.testCase?.automation == choice, "\(choice)")
            #expect(!model.hasUnsavedChanges, "\(choice)")
        }
    }

    @Test func draftDifferingOnlyInReadOnlyStepsSavesWithoutRequest() async throws {
        let fixture = EditorFixture()
        fixture.loadEditor(with: Self.serverCase(title: "Original"))
        fixture.model.changedTestCase?.steps = []
        #expect(fixture.model.hasUnsavedChanges)
        try await fixture.model.updateTestCaseData()
        #expect(fixture.network.methods.isEmpty)
        #expect(fixture.model.isUploadingSuccess && !fixture.model.hasUnsavedChanges)
    }

    // MARK: - Перечитывание после PATCH

    @Test func savedCaseIsRereadAndServerVersionBecomesCacheAndRecent() async throws {
        let fixture = EditorFixture()
        fixture.loadEditor(with: Self.serverCase(title: "Original"))
        fixture.network.getReplies = [.success(Self.serverCase(title: "Normalized by server", priority: 1))]
        fixture.model.updateValue(for: .title, value: "Renamed")
        try await fixture.model.updateTestCaseData()
        #expect(fixture.network.methods == [.patch, .get])
        #expect(fixture.model.testCase?.title == "Normalized by server")
        #expect(fixture.model.changedTestCase == fixture.model.testCase)
        #expect(fixture.cachedCase()?.title == "Normalized by server")
        let recent = try #require(fixture.dao.getRecentCases(projectCode: "A").first)
        #expect(recent.title == "Normalized by server" && recent.priority == 1)
        #expect(fixture.model.isUploadingSuccess)
    }

    @Test func failedRereadKeepsSaveSuccessfulAndCachesDraft() async throws {
        for reply: Result<TestCaseEntity, API.NetError> in [
            .failure(.noInternetConnection),
            .success(Self.serverCase(id: 99, title: "Other case"))
        ] {
            let fixture = EditorFixture()
            fixture.loadEditor(with: Self.serverCase(title: "Original"))
            fixture.network.getReplies = [reply]
            fixture.model.updateValue(for: .title, value: "Renamed")
            try await fixture.model.updateTestCaseData()
            #expect(fixture.model.isUploadingSuccess)
            #expect(fixture.model.testCase?.title == "Renamed")
            #expect(fixture.cachedCase()?.title == "Renamed")
        }
    }

    @Test func rejectedPatchKeepsDraftAndSkipsReread() async throws {
        let fixture = EditorFixture()
        fixture.loadEditor(with: Self.serverCase(title: "Original"))
        fixture.network.patchStatus = false
        fixture.model.updateValue(for: .title, value: "Renamed")
        do {
            try await fixture.model.updateTestCaseData()
            Issue.record("status:false must fail the save")
        } catch {}
        #expect(fixture.network.methods == [.patch])
        #expect(fixture.model.changedTestCase?.title == "Renamed" && fixture.model.testCase?.title == "Original")
        #expect(fixture.cachedCase()?.title == "Original")
    }

    // MARK: - Сверка кеша с сервером

    @Test func cleanDraftIsReplacedByServerVersionAfterCachedOpen() async throws {
        let fixture = EditorFixture()
        fixture.seedCache(Self.serverCase(title: "Cached v1"))
        fixture.network.getReplies = [.success(Self.serverCase(title: "Server v2"))]
        try await fixture.model.fetchCaseDataJSON()
        #expect(fixture.model.testCase?.title == "Server v2")
        #expect(fixture.model.changedTestCase?.title == "Server v2")
        #expect(fixture.cachedCase()?.title == "Server v2")
        #expect(fixture.dao.getRecentCases(projectCode: "A").map(\.title) == ["Server v2"])
    }

    @Test func dirtyDraftSurvivesRevalidationWhileCacheIsRefreshed() async throws {
        let fixture = EditorFixture()
        fixture.seedCache(Self.serverCase(title: "Cached v1"))
        fixture.network.getReplies = [.success(Self.serverCase(title: "Server v2"))]
        fixture.network.suspendedGetCalls = [1]
        let open = Task { try await fixture.model.fetchCaseDataJSON() }
        await waitForCondition { fixture.network.pendingGet != nil }
        #expect(fixture.model.testCase?.title == "Cached v1")
        fixture.model.updateValue(for: .title, value: "User edit")
        fixture.network.resumePendingGet()
        try await open.value
        #expect(fixture.model.changedTestCase?.title == "User edit")
        #expect(fixture.model.testCase?.title == "Cached v1")
        #expect(fixture.cachedCase()?.title == "Server v2")
    }

    @Test func revalidationFailureWithCacheIsSilent() async throws {
        let fixture = EditorFixture()
        fixture.seedCache(Self.serverCase(title: "Cached v1"))
        fixture.network.getReplies = [.failure(.noInternetConnection)]
        try await fixture.model.fetchCaseDataJSON()
        #expect(fixture.model.testCase?.title == "Cached v1")
        #expect(!fixture.model.hasUnsavedChanges)
    }

    @Test func loadFailureWithoutCacheIsReported() async {
        let fixture = EditorFixture()
        fixture.network.getReplies = [.failure(.noInternetConnection)]
        do {
            try await fixture.model.fetchCaseDataJSON()
            Issue.record("Without cache a failed load must be reported")
        } catch {}
        #expect(fixture.model.testCase == nil)
    }

    @Test func revalidationResponseIsDroppedOnceSaveStarted() async throws {
        let fixture = EditorFixture()
        fixture.seedCache(Self.serverCase(title: "Cached v1"))
        fixture.network.getReplies = [
            .success(Self.serverCase(title: "Stale v2")),
            .success(Self.serverCase(title: "Saved v3"))
        ]
        fixture.network.suspendedGetCalls = [1]
        let open = Task { try await fixture.model.fetchCaseDataJSON() }
        await waitForCondition { fixture.network.pendingGet != nil }
        fixture.model.updateValue(for: .title, value: "Saved v3")
        try await fixture.model.updateTestCaseData()
        #expect(fixture.cachedCase()?.title == "Saved v3")
        fixture.network.resumePendingGet()
        try await open.value
        #expect(fixture.model.testCase?.title == "Saved v3")
        #expect(fixture.cachedCase()?.title == "Saved v3")
    }

    @Test func revalidationAfterSessionChangeNeitherPublishesNorCaches() async throws {
        let fixture = EditorFixture()
        fixture.seedCache(Self.serverCase(title: "Cached v1"))
        fixture.network.getReplies = [.success(Self.serverCase(title: "Server v2"))]
        fixture.network.suspendedGetCalls = [1]
        let open = Task { try await fixture.model.fetchCaseDataJSON() }
        await waitForCondition { fixture.network.pendingGet != nil }
        fixture.session.activate(ownerID: "other")
        fixture.network.resumePendingGet()
        try await open.value
        #expect(fixture.model.testCase?.title == "Cached v1")
        fixture.session.activate(ownerID: "owner")
        #expect(fixture.cachedCase()?.title == "Cached v1")
    }

    // MARK: - Фикстуры

    /// Кейс в формате ответа `GET /case/{code}/{id}`; коды полей — по `GET /system_field`.
    static func serverCase(
        id: Int = 7,
        title: String,
        priority: Int = 2,
        automation: Int = 0
    ) -> TestCaseEntity {
        let json = """
        {
          "id": \(id), "position": 1, "title": "\(title)",
          "description": "Description", "preconditions": "Pre", "postconditions": "Post",
          "severity": 4, "priority": \(priority), "type": 1, "layer": 1, "behavior": 2,
          "automation": \(automation), "status": 0, "is_flaky": 0, "suite_id": 3,
          "links": [], "custom_fields": [], "attachments": [], "params": [], "tags": [],
          "member_id": 1, "author_id": 1, "steps_type": "classic",
          "steps": [{"hash": "step-1", "position": 1, "attachments": [],
                     "action": "Open", "expected_result": "Opened", "data": "", "steps": []}]
        }
        """
        // Фикстура задана литералом выше; при ошибке декодирования тест должен упасть сразу.
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(TestCaseEntity.self, from: Data(json.utf8))
    }
}

@MainActor
private final class EditorFixture {
    let session = SessionContext(ownerID: "owner")
    let network = EditorNetwork()
    let dao: RealmManager
    let model: TestCaseEditorViewModel

    init() {
        dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        model = TestDependencies.detail(
            reference: editorReference,
            network: network,
            dao: dao,
            session: session
        )
    }

    /// Открытый редактор с чистым черновиком, без сетевых запросов.
    func loadEditor(with value: TestCaseEntity) {
        model.changedTestCase = value
        model.testCase = value
        seedCache(value)
    }

    func seedCache(_ value: TestCaseEntity) {
        #expect(dao.saveTestCase(value, reference: editorReference, stamp: session.capture()))
    }

    func cachedCase() -> TestCaseEntity? {
        dao.getTestCase(reference: editorReference)
    }
}

/// Сеть редактора: N-й GET получает `getReplies[N-1]` (выбранные вызовы можно приостановить),
/// PATCH кодирует тело тем же `API.encodeBody`, что и `APIManager`.
/// Состояние на MainActor; методы протокола `nonisolated`, чтобы `T.Type` не пересекал границу акторов.
@MainActor
private final class EditorNetwork: NetworkManager {
    var getReplies: [Result<TestCaseEntity, API.NetError>] = []
    var suspendedGetCalls: Set<Int> = []
    var patchStatus = true
    private(set) var methods: [API.HTTPMethod] = []
    private(set) var patchBodies: [[String: Any]] = []
    private(set) var pendingGet: CheckedContinuation<Void, Never>?
    private var getCalls = 0

    func resumePendingGet() {
        let continuation = pendingGet
        pendingGet = nil
        continuation?.resume()
    }

    nonisolated func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem],
        with data: Encodable?,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        switch operation {
        case .getCase:
            let value = try await nextGetReply(method: operation.httpMethod)
            guard let response = TestCaseModel(status: true, result: value) as? T
            else { throw .serializationError("Fixture type mismatch") }
            return response
        case .updateCase:
            var encoded: Data?
            if let data { encoded = try API.encodeBody(data) }
            let reply = await recordPatch(method: operation.httpMethod, body: encoded)
            return try API.decodeResponse(from: reply, as: modelType)
        default:
            await recordMethod(operation.httpMethod)
            throw .invalidRequest("Unexpected operation \(operation.rawValue)")
        }
    }

    private func recordMethod(_ method: API.HTTPMethod) {
        methods.append(method)
    }

    /// Регистрирует GET, при необходимости ждёт `resumePendingGet()` и отдаёт ответ по номеру вызова.
    private func nextGetReply(method: API.HTTPMethod) async throws(API.NetError) -> TestCaseEntity {
        methods.append(method)
        getCalls += 1
        let call = getCalls
        if suspendedGetCalls.contains(call) {
            await withCheckedContinuation { pendingGet = $0 }
        }
        guard call <= getReplies.count else { throw .invalidRequest("Unexpected GET #\(call)") }
        switch getReplies[call - 1] {
        case .failure(let error): throw error
        case .success(let value): return value
        }
    }

    /// Регистрирует PATCH с телом и возвращает ответ с текущим `patchStatus`.
    private func recordPatch(method: API.HTTPMethod, body: Data?) -> Data {
        methods.append(method)
        let object = body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        patchBodies.append(object ?? [:])
        return Data(#"{"status":\#(patchStatus),"result":{"id":7}}"#.utf8)
    }

    nonisolated func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .invalidURL }

    nonisolated func auth(by token: String) async throws -> Bool { true }
}
