import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

@Suite(.timeLimit(.minutes(1))) @MainActor
struct FormRequestBodyTests {
    /// Сервер не меняет поля, отсутствующие в теле PATCH (проверено на тестовом проекте 2026-11-20),
    /// поэтому шаги, теги, вложения и набор остаются нетронутыми, только если их нет в теле.
    @Test func priorityPatchSendsOnlyPriorityAndKeepsUneditedFieldsLocally() async throws {
        let session = SessionContext(ownerID: "owner")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let network = draftNetwork()
        let fixtureData = Data(Self.completeCaseFixture.utf8)
        let initial = try JSONDecoder().decode(TestCaseEntity.self, from: fixtureData)
        let model = TestDependencies.detail(
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
        #expect(Set(payload.keys) == ["priority"])
        #expect(payload["priority"] as? Int == 1)
        // Фейк отвечает на перечитывание телом без кейса — сохранение откатывается на черновик.
        #expect(network.methods == [.patch, .get])
        var expected = initial
        expected.priority = .high
        #expect(model.testCase == expected && model.changedTestCase == expected)
        #expect(dao.getTestCase(reference: .init(projectCode: "A", caseID: initial.id))?.priority == .high)
        #expect(model.isUploadingSuccess && !model.hasUnsavedChanges)
    }

    // MARK: - Создание набора и кейса: тело запроса и ответ с status:false

    /// Ловит: `parentId` выпал из тела набора; ключ ушёл не в snake_case (`parentId`);
    /// `description` и `preconditions` перепутаны местами.
    @Test func suiteBodyCarriesDraftFieldsAndParentID() async throws {
        let network = draftNetwork()
        let model = TestDependencies.creator(
            projectCode: "A",
            parentSuiteId: 9,
            network: network,
            session: SessionContext(ownerID: "owner")
        )
        model.creatingSuite.title = "Suite title"
        model.creatingSuite.itemDescription = "Suite description"
        model.creatingSuite.preconditions = "Suite preconditions"
        try await model.createNewEntity()
        let payload = try lastPayload(of: network)
        #expect(Set(payload.keys) == ["title", "description", "preconditions", "parent_id"])
        #expect(payload["title"] as? String == "Suite title")
        #expect(payload["description"] as? String == "Suite description")
        #expect(payload["preconditions"] as? String == "Suite preconditions")
        #expect(payload["parent_id"] as? Int == 9)
    }

    /// Ловит: набор в корне отправляет `parent_id` (0 или null) вместо отсутствия ключа.
    @Test func rootSuiteBodyHasNoParentIDKey() async throws {
        let network = draftNetwork()
        let model = TestDependencies.creator(
            projectCode: "A",
            network: network,
            session: SessionContext(ownerID: "owner")
        )
        model.creatingSuite.title = "Root suite"
        try await model.createNewEntity()
        let payload = try lastPayload(of: network)
        #expect(Set(payload.keys) == ["title", "description", "preconditions"])
        #expect(payload["title"] as? String == "Root suite")
    }

    /// Ловит: в тело кейса уходит черновик набора, либо `suite_id` теряется или меняет имя.
    @Test func caseBodyCarriesTitleAndSuiteID() async throws {
        let network = draftNetwork()
        let model = TestDependencies.creator(
            projectCode: "A",
            parentSuiteId: 9,
            network: network,
            session: SessionContext(ownerID: "owner")
        )
        model.creatingSuite.title = "Suite title that must not be sent"
        model.creatingEntityIsSuite = false
        model.creatingTestCase.title = "Case title"
        try await model.createNewEntity()
        let payload = try lastPayload(of: network)
        #expect(payload["title"] as? String == "Case title")
        #expect(payload["suite_id"] as? Int == 9)
        #expect(payload["parent_id"] == nil)
    }

    /// Ловит: кейс в корне пропускает `suite_id` вместо явного `null`.
    @Test func rootCaseBodySendsNullSuiteID() async throws {
        let network = draftNetwork()
        let model = TestDependencies.creator(
            projectCode: "A",
            network: network,
            session: SessionContext(ownerID: "owner")
        )
        model.creatingEntityIsSuite = false
        model.creatingTestCase.title = "Root case"
        try await model.createNewEntity()
        let payload = try lastPayload(of: network)
        #expect(payload["title"] as? String == "Root case")
        #expect(payload["suite_id"] is NSNull)
    }

    /// Ловит: удалён guard `status` у набора (или `baselineSuite` обновляется до проверки) —
    /// отказ сервера считается успехом, черновик «сохранён», колбэк закрытия формы вызван.
    @Test func suiteCreationWithFalseStatusFailsAndKeepsTheDraftUnsaved() async {
        let network = draftNetwork()
        network.respond = ScriptedNetwork.body(#"{"status":false,"result":{"id":1}}"#)
        let model = TestDependencies.creator(
            projectCode: "A",
            network: network,
            session: SessionContext(ownerID: "owner")
        )
        var finished = 0
        model.creatingFinishCallback = { finished += 1 }
        model.creatingSuite.title = "Suite"
        let error = await thrownNetError { try await model.createNewEntity() }
        #expect(invalidRequestMessage(error) == "The entity could not be created")
        #expect(network.methods == [.post])
        #expect(!model.isEntityWasCreated && !model.isSaving && finished == 0)
        #expect(model.suiteHasUnsavedChanges && model.canCreate)
    }

    /// Ловит: удалён guard `status` у кейса (или `baselineCase` обновляется до проверки).
    @Test func caseCreationWithFalseStatusFailsAndKeepsTheDraftUnsaved() async {
        let network = draftNetwork()
        network.respond = ScriptedNetwork.body(#"{"status":false,"result":{"id":1}}"#)
        let model = TestDependencies.creator(
            projectCode: "A",
            network: network,
            session: SessionContext(ownerID: "owner")
        )
        var finished = 0
        model.creatingFinishCallback = { finished += 1 }
        model.creatingEntityIsSuite = false
        model.creatingTestCase.title = "Case"
        let error = await thrownNetError { try await model.createNewEntity() }
        #expect(invalidRequestMessage(error) == "The entity could not be created")
        #expect(network.methods == [.post])
        #expect(!model.isEntityWasCreated && !model.isSaving && finished == 0)
        #expect(model.caseHasUnsavedChanges && model.canCreate)
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
}

@MainActor
private func lastPayload(of network: ScriptedNetwork) throws -> [String: Any] {
    let body = try #require(network.capturedBodies.last)
    return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
}

/// Успешный ответ создания по умолчанию для сети форм.
private let draftReply = #"{"status":true,"result":{"id":1}}"#

/// Сеть форм на общем ядре: по умолчанию успешный ответ `draftReply`.
@MainActor
private func draftNetwork() -> ScriptedNetwork {
    ScriptedNetwork(respond: ScriptedNetwork.body(draftReply))
}

