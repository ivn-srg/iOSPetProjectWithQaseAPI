import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

@Suite @MainActor
struct FormDraftTests {
    @Test func selectedIDsAndParentAreEncodedFromTheCaseDraft() throws {
        let model = CreateSuiteOrCaseViewModel(
            projectCode: "A",
            parentSuiteId: 9,
            session: SessionContext(ownerID: "owner")
        )
        model.creatingEntityIsSuite = false
        model.updateValue(for: .priority, value: Priority.high.menuItem.id)
        model.updateValue(for: .severity, value: Severity.critical.menuItem)
        model.updateValue(for: .isFlaky, value: true)
        model.selectParent(12, forSuite: false)
        #expect(model.creatingTestCase.priority == .high)
        #expect(model.creatingTestCase.severity == .critical)
        #expect(model.creatingTestCase.isFlaky)
        #expect(model.creatingSuite.parentId == 9)
        let payload = try #require(JSONSerialization
            .jsonObject(with: JSONEncoder().encode(model.creatingTestCase.dictOfValues)) as? [String: Any])
        #expect(payload["suite_id"] as? Int == 12)
        model.selectParent(0, forSuite: false)
        #expect(model.creatingTestCase.suiteId == nil)
        model.selectParent(nil, forSuite: true)
        #expect(model.creatingSuite.parentId == nil)
    }

    @Test func twoDraftsRemainIndependentAndWhitespaceCannotCreate() async {
        let network = FormDraftNetwork()
        let model = CreateSuiteOrCaseViewModel(
            projectCode: "A",
            network: network,
            session: SessionContext(ownerID: "owner")
        )
        model.creatingSuite.title = "Suite"
        model.creatingEntityIsSuite = false
        model.creatingTestCase.title = " \n "
        #expect(model.suiteHasUnsavedChanges && model.caseHasUnsavedChanges)
        #expect(!model.canCreate && !model.canSaveAllDrafts)
        do { try await model.createNewEntity()
            Issue.record("Whitespace cannot be posted") } catch {}
        #expect(network.methods.isEmpty)
        #expect(model.creatingSuite.title == "Suite")
        model.creatingTestCase.title = "Case"
        #expect(model.canSaveAllDrafts)
    }

    @Test func partialSuccessDoesNotResendTheAlreadyConfirmedSuite() async throws {
        let network = FormDraftNetwork()
        let model = CreateSuiteOrCaseViewModel(
            projectCode: "A",
            network: network,
            session: SessionContext(ownerID: "owner")
        )
        model.creatingSuite.title = "Suite"
        model.creatingTestCase.title = "Case"
        try await model.createNewEntity()
        #expect(!model.suiteHasUnsavedChanges && model.caseHasUnsavedChanges)
        model.creatingEntityIsSuite = false
        network.error = .noInternetConnection
        do { try await model.createNewEntity()
            Issue.record("Offline save must fail") } catch {}
        #expect(!model.isEntityWasCreated && !model.isSaving)
        #expect(model.creatingTestCase.title == "Case" && model.caseHasUnsavedChanges)
        model.creatingEntityIsSuite = true
        #expect(!model.canCreate)
        do { try await model.createNewEntity()
            Issue.record("Confirmed snapshot must not be duplicated") } catch {}
        #expect(network.methods.count == 2)
        network.error = nil
        model.creatingEntityIsSuite = false
        try await model.createNewEntity()
        #expect(!model.hasAnyUnsavedChanges && network.methods.count == 3)
    }

    @Test func busyCreateRejectsAnotherRequestAndParentMutation() async throws {
        let network = FormDraftNetwork()
        let model = CreateSuiteOrCaseViewModel(
            projectCode: "A",
            network: network,
            session: SessionContext(ownerID: "owner")
        )
        model.creatingSuite.title = "Suite"
        var request: Task<Void, Error>?
        await withCheckedContinuation { started in
            network.onStarted = { started.resume() }
            network.shouldSuspend = true
            request = Task { try await model.createNewEntity() }
        }
        #expect(model.isSaving && !model.canCreate)
        model.selectParent(7, forSuite: true)
        #expect(model.creatingSuite.parentId == nil)
        do { try await model.createNewEntity()
            Issue.record("Busy save must fail") } catch {}
        #expect(network.methods.count == 1)
        network.release?.resume()
        try await request?.value
        #expect(!model.isSaving && !model.suiteHasUnsavedChanges)
    }

    @Test func staleCreateResponseDoesNotPublishSuccessOrConfirmDraft() async throws {
        let session = SessionContext(ownerID: "old")
        let network = FormDraftNetwork()
        let model = CreateSuiteOrCaseViewModel(projectCode: "A", network: network, session: session)
        var finished = false
        model.creatingFinishCallback = { finished = true }
        model.creatingSuite.title = "Old owner"
        network.beforeResponse = { session.activate(ownerID: "new") }
        do { try await model.createNewEntity()
            Issue.record("Late old response must fail") } catch {}
        #expect(!finished && !model.isEntityWasCreated && !model.isSaving)
        #expect(model.suiteHasUnsavedChanges && !model.isSessionCurrent)
        do { try await model.createNewEntity()
            Issue.record("Stale form must not send") } catch {}
        #expect(network.methods.count == 1)
    }

    @Test func editorNoChangeAndFailureKeepCompleteDraft() async throws {
        let session = SessionContext(ownerID: "owner")
        let network = FormDraftNetwork()
        let model = DetailTabbarControllerViewModel(
            reference: .init(projectCode: "A", caseID: 1),
            network: network,
            session: session
        )
        var initial = TestCaseEntity.empty
        initial.title = "Case"
        initial.suiteId = 8
        model.changedTestCase = initial
        model.testCase = initial
        #expect(!model.canSaveChanges)
        do { try await model.updateTestCaseData()
            Issue.record("Unchanged editor must not patch") } catch {}
        model.updateValue(for: .priority, value: Priority.high.menuItem)
        let draft = model.changedTestCase
        network.error = .timeout
        do { try await model.updateTestCaseData()
            Issue.record("Failed update must preserve draft") } catch {}
        #expect(model.changedTestCase == draft && model.testCase == initial)
        #expect(model.changedTestCase?.suiteId == 8)
        #expect(model.canSaveChanges && !model.isUploadingSuccess && !model.isSaving)
    }

    @Test func priorityPatchPreservesNestedStepsAndEveryExistingPayloadField() async throws {
        let session = SessionContext(ownerID: "owner")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let network = FormDraftNetwork()
        let fixtureData = Data(Self.completeCaseFixture.utf8)
        let initial = try JSONDecoder().decode(TestCaseEntity.self, from: fixtureData)
        let fixture = try #require(JSONSerialization.jsonObject(with: fixtureData) as? [String: Any])
        let model = DetailTabbarControllerViewModel(
            reference: .init(projectCode: "A", caseID: initial.id),
            network: network,
            dao: dao,
            session: session
        )
        model.changedTestCase = initial
        model.testCase = initial
        model.updateValue(for: .priority, value: Priority.high.menuItem.id)
        try await model.updateTestCaseData()
        let body = try #require(network.capturedBodies.last)
        let payload = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(network.methods == [.patch])
        #expect(payload["priority"] as? Int == Priority.high.menuItem.id)
        #expect(payload["suite_id"] as? Int == 8)
        #expect(payload["attachments"] as? [String] == ["case-attachment-a", "case-attachment-b"])
        #expect(payload["tags"] as? [String] == ["regression", "mobile"])
        let actualSteps = try #require(payload["steps"] as? NSArray)
        let fixtureSteps = try #require(fixture["steps"] as? NSArray)
        #expect(actualSteps.isEqual(fixtureSteps))
        let firstStep = try #require((payload["steps"] as? [[String: Any]])?.first)
        let nestedStep = try #require((firstStep["steps"] as? [[String: Any]])?.first)
        #expect(firstStep["attachments"] as? [Int] == [101, 102])
        #expect(nestedStep["attachments"] as? [Int] == [201])
        #expect(nestedStep["expected_result"] as? String == "Nested result\nremains intact")
        #expect(nestedStep["shared_step_nested_hash"] as? String == "shared-nested")
        for key in ["title", "description", "preconditions", "postconditions"] {
            #expect(payload[key] as? String == fixture[key] as? String)
        }
        for key in ["severity", "type", "layer", "behavior", "automation", "status", "is_flaky"] {
            #expect(payload[key] as? Int == fixture[key] as? Int)
        }
        #expect(model.changedTestCase?.links == initial.links)
        #expect(model.changedTestCase?.customFields == initial.customFields)
        #expect(model.changedTestCase?.params == initial.params)
        #expect(model.changedTestCase?.stepsType == initial.stepsType)
        #expect(model.testCase?.attachments == initial.attachments)
        #expect(!model.hasUnsavedChanges)
    }

    @Test func everyTypeMenuIDRoundTripsThroughBothForms() {
        let session = SessionContext(ownerID: "owner")
        let creator = CreateSuiteOrCaseViewModel(projectCode: "A", session: session)
        creator.creatingEntityIsSuite = false
        let editor = DetailTabbarControllerViewModel(
            reference: .init(projectCode: "A", caseID: 1),
            session: session
        )
        editor.changedTestCase = .empty
        for type in Types.allCases {
            #expect(Types(type.menuItem.id) == type)
            creator.updateValue(for: .type, value: type.menuItem.id)
            editor.updateValue(for: .type, value: type.menuItem)
            #expect(creator.creatingTestCase.type == type)
            #expect(editor.changedTestCase?.type == type)
        }
    }

    private static let completeCaseFixture = #"""
    {
      "id": 1, "position": 7, "title": "Complete case",
      "description": "Detailed description", "preconditions": "Registered user", "postconditions": "Logged in",
      "severity": 2, "priority": 2, "type": 9, "layer": 2, "behavior": 3,
      "automation": 1, "status": 0, "is_flaky": 1, "suite_id": 8,
      "attachments": ["case-attachment-a", "case-attachment-b"], "tags": ["regression", "mobile"],
      "links": ["https://example.invalid/reference"], "custom_fields": ["retained-custom-field"],
      "params": ["retained-param"], "member_id": 23, "author_id": 24, "steps_type": "classic",
      "steps": [
        {
          "hash": "parent-step", "position": 1, "shared_step_hash": "shared-parent",
          "shared_step_nested_hash": "", "attachments": [101, 102],
          "action": "Open login\nUse registered account", "expected_result": "Form opens", "data": "parent data",
          "steps": [
            {
              "hash": "nested-step", "position": 1, "shared_step_hash": "shared-parent",
              "shared_step_nested_hash": "shared-nested", "attachments": [201],
              "action": "Enter credentials", "expected_result": "Nested result\nremains intact", "data": "nested data",
              "steps": []
            }
          ]
        },
        {
          "hash": "second-step", "position": 2, "shared_step_hash": "",
          "shared_step_nested_hash": "", "attachments": [],
          "action": "Close application", "expected_result": "", "data": "", "steps": []
        }
      ]
    }
    """#

    @Test func busyEditorDoesNotPatchTwiceAndLateResponseCannotReplaceCache() async throws {
        let session = SessionContext(ownerID: "old")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let network = FormDraftNetwork()
        let reference = TestCaseReference(projectCode: "A", caseID: 0)
        let model = DetailTabbarControllerViewModel(
            reference: reference,
            network: network,
            dao: dao,
            session: session
        )
        var initial = TestCaseEntity.empty
        initial.title = "Original"
        #expect(dao.saveTestCase(initial, reference: reference, stamp: session.capture()))
        model.changedTestCase = initial
        model.testCase = initial
        model.updateValue(for: .title, value: "Retained draft")
        var finished = false
        model.updatingFinishCallback = { finished = true }
        var request: Task<Void, Error>?
        await withCheckedContinuation { started in
            network.onStarted = { started.resume() }
            network.shouldSuspend = true
            request = Task { try await model.updateTestCaseData() }
        }
        #expect(model.isSaving && !model.canSaveChanges)
        do { try await model.updateTestCaseData()
            Issue.record("Busy editor must not patch twice") } catch {}
        #expect(network.methods.count == 1)
        session.activate(ownerID: "new")
        network.release?.resume()
        do { try await request?.value
            Issue.record("Late response must fail") } catch {}
        #expect(!finished && !model.isUploadingSuccess && !model.isSaving)
        #expect(model.testCase?.title == "Original" && model.changedTestCase?.title == "Retained draft")
        #expect(dao.getTestCase(reference: reference) == nil)
        session.activate(ownerID: "old")
        #expect(dao.getTestCase(reference: reference)?.title == "Original")
    }

}

private final class FormDraftNetwork: NetworkManager {
    var methods: [API.HTTPMethod] = []
    var capturedBodies: [Data] = []
    var error: API.NetError?
    var shouldSuspend = false
    var onStarted: (() -> Void)?
    var beforeResponse: (() -> Void)?
    var release: CheckedContinuation<Void, Never>?

    func performRequest<T: Decodable>(
        with data: Encodable?,
        from urlString: URL?,
        method: API.HTTPMethod,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        methods.append(method)
        if let data {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            do { capturedBodies.append(try encoder.encode(data)) }
            catch { throw .serializationError("Fixture payload encoding failed") }
        }
        if shouldSuspend {
            await withCheckedContinuation { continuation in release = continuation
                onStarted?() }
        }
        beforeResponse?()
        if let error { throw error }
        return try API.decodeResponse(from: Data(#"{"status":true,"result":{"id":1}}"#.utf8), as: modelType)
    }

    func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem],
        with data: Encodable?,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        try await performRequest(
            with: data,
            from: API.makeURL(for: operation, pathParameters: pathParameters, queryItems: queryItems),
            method: operation.httpMethod,
            modelType: modelType
        )
    }

    func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .invalidURL }
    func composeURL(
        for method: API.Endpoint,
        urlComponents: [String?]?,
        queryItems: [API.QueryParams: Int?]?
    ) -> URL? {
        URL(string: API.BASE_URL + "/" + method.rawValue + "/" + (urlComponents ?? []).compactMap { $0 }
            .joined(separator: "/"))
    }

    func composeURL(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem]
    ) -> URL? { API.makeURL(
        for: operation,
        pathParameters: pathParameters,
        queryItems: queryItems
    ) }
    func auth(by token: String) async throws -> Bool { true }
}
