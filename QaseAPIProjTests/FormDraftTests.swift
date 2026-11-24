import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing
import UIKit

@Suite(.timeLimit(.minutes(1))) @MainActor
struct FormDraftTests {
    @Test func selectedIDsAndParentAreEncodedFromTheCaseDraft() throws {
        let model = TestDependencies.creator(
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
        let model = TestDependencies.creator(
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
        let model = TestDependencies.creator(
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
            Issue.record("Confirmed snapshot must not be duplicated")
        } catch {}
        #expect(network.methods.count == 2)
        network.error = nil
        model.creatingEntityIsSuite = false
        try await model.createNewEntity()
        #expect(!model.hasAnyUnsavedChanges && network.methods.count == 3)
    }

    @Test func busyCreateRejectsAnotherRequestAndParentMutation() async throws {
        let network = FormDraftNetwork()
        let model = TestDependencies.creator(
            projectCode: "A",
            network: network,
            session: SessionContext(ownerID: "owner")
        )
        model.creatingSuite.title = "Suite"
        var request: Task<Void, Error>?
        network.shouldSuspend = true
        request = Task { try await model.createNewEntity() }
        await waitForCondition { network.release != nil }
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
        let model = TestDependencies.creator(projectCode: "A", network: network, session: session)
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
        let model = TestDependencies.detail(
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
            Issue.record("Failed update must preserve draft")
        } catch {}
        #expect(model.changedTestCase == draft && model.testCase == initial)
        #expect(model.changedTestCase?.suiteId == 8)
        #expect(model.canSaveChanges && !model.isUploadingSuccess && !model.isSaving)
    }

    /// Сервер не меняет поля, отсутствующие в теле PATCH (проверено на тестовом проекте 2026-11-20),
    /// поэтому шаги, теги, вложения и набор остаются нетронутыми, только если их нет в теле.
    @Test func priorityPatchSendsOnlyPriorityAndKeepsUneditedFieldsLocally() async throws {
        let session = SessionContext(ownerID: "owner")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let network = FormDraftNetwork()
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

    @Test func everyFieldMenuIDRoundTripsThroughBothForms() {
        func checkMenu<T: CaseIterable & MenuDataSource & Equatable>(
            _ type: T.Type,
            apiValue: (T) -> Int,
            make: (Int) -> T
        ) {
            for value in T.allCases {
                #expect(value.menuItem.id == apiValue(value))
                #expect(make(value.menuItem.id) == value)
            }
        }
        checkMenu(Severity.self, apiValue: { $0.apiValue }, make: { Severity($0) })
        checkMenu(Priority.self, apiValue: { $0.apiValue }, make: { Priority($0) })
        checkMenu(Status.self, apiValue: { $0.apiValue }, make: { Status($0) })
        checkMenu(AutomationStatus.self, apiValue: { $0.apiValue }, make: { AutomationStatus($0) })
        checkMenu(Behavior.self, apiValue: { $0.apiValue }, make: { Behavior($0) })
        checkMenu(Layer.self, apiValue: { $0.apiValue }, make: { Layer($0) })
        checkMenu(Types.self, apiValue: { $0.apiValue }, make: { Types($0) })

        let session = SessionContext(ownerID: "owner")
        let creator = TestDependencies.creator(projectCode: "A", session: session)
        creator.creatingEntityIsSuite = false
        let editor = TestDependencies.detail(reference: .init(projectCode: "A", caseID: 1), session: session)
        editor.changedTestCase = .empty
        for type in Types.allCases {
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
        let model = TestDependencies.detail(
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
        network.shouldSuspend = true
        request = Task { try await model.updateTestCaseData() }
        await waitForCondition { network.release != nil }
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

    // MARK: - Создание набора и кейса: тело запроса и ответ с status:false

    /// Ловит: `parentId` выпал из тела набора; ключ ушёл не в snake_case (`parentId`);
    /// `description` и `preconditions` перепутаны местами.
    @Test func suiteBodyCarriesDraftFieldsAndParentID() async throws {
        let network = FormDraftNetwork()
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
        let network = FormDraftNetwork()
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
        let network = FormDraftNetwork()
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
        let network = FormDraftNetwork()
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
        let network = FormDraftNetwork()
        network.responseBody = #"{"status":false,"result":{"id":1}}"#
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
        let network = FormDraftNetwork()
        network.responseBody = #"{"status":false,"result":{"id":1}}"#
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

    // MARK: - saveDraft формы создания набора и кейса

    /// Ловит: сохраняется только активный черновик; порядок POST не «набор, затем кейс»;
    /// `isSavingSequence` не сбрасывается в `defer` (форма остаётся заблокированной);
    /// активный сегмент модели не возвращается.
    @Test func saveDraftPostsSuiteThenCaseAndUnlocksTheForm() async throws {
        let form = CreateFormFixture()
        form.model.creatingSuite.title = "Suite"
        form.model.creatingTestCase.title = "Case"
        try await form.controller.saveDraft()
        #expect(form.network.operations == [.createSuite, .createCase])
        #expect(form.created.count == 2)
        #expect(!form.controller.isSavingDraft)
        #expect(form.closeIsEnabled)
        #expect(form.model.creatingEntityIsSuite)
        #expect(!form.model.hasAnyUnsavedChanges)
    }

    /// Ловит: чистый черновик набора тоже уходит в POST (удалён `guard dirty`), и тогда пустой набор
    /// ломает сохранение кейса; сегмент модели не возвращается после сохранения кейса.
    @Test func saveDraftSendsOnlyTheChangedCase() async throws {
        let form = CreateFormFixture()
        form.model.creatingTestCase.title = "Case"
        try await form.controller.saveDraft()
        #expect(form.network.operations == [.createCase])
        #expect(form.created.count == 1)
        #expect(form.model.creatingEntityIsSuite)
        #expect(!form.model.hasAnyUnsavedChanges)
        #expect(!form.controller.isSavingDraft && form.closeIsEnabled)
    }

    /// Ловит: ошибка второго POST проглатывается; `onEntityCreated` вызывается для неудавшейся части;
    /// форма остаётся заблокированной после ошибки (нет сброса в `defer`); после ошибки виден
    /// подтверждённый набор, а несохранённый кейс скрыт (APP-089).
    @Test func saveDraftFailureOnTheSecondRequestKeepsConfirmedSuiteAndUnlocksTheForm() async {
        let form = CreateFormFixture()
        form.network.failure = (request: 2, error: .timeout)
        form.model.creatingSuite.title = "Suite"
        form.model.creatingTestCase.title = "Case"
        let error = await thrownNetError { try await form.controller.saveDraft() }
        guard case .timeout? = error else {
            Issue.record("Expected the timeout of the second POST, got \(String(describing: error))")
            return
        }
        #expect(form.network.operations == [.createSuite, .createCase])
        #expect(form.created.count == 1)
        #expect(!form.model.suiteHasUnsavedChanges && form.model.caseHasUnsavedChanges)
        #expect(!form.model.creatingEntityIsSuite)
        #expect(!form.controller.isSavingDraft)
        #expect(form.closeIsEnabled)
    }

    /// Ловит: после сбоя первого POST форма возвращает исходный сегмент кейса, а несохранённый
    /// набор остаётся скрытым (APP-089).
    @Test func saveDraftFailureOnTheFirstRequestShowsTheUnsavedSuite() async {
        let form = CreateFormFixture()
        form.network.failure = (request: 1, error: .timeout)
        form.model.creatingSuite.title = "Suite"
        form.model.creatingTestCase.title = "Case"
        form.model.creatingEntityIsSuite = false
        _ = await thrownNetError { try await form.controller.saveDraft() }
        #expect(form.network.operations == [.createSuite])
        #expect(form.created.count == 0)
        #expect(form.model.suiteHasUnsavedChanges && form.model.caseHasUnsavedChanges)
        #expect(form.model.creatingEntityIsSuite)
        #expect(form.closeIsEnabled)
    }

    /// Ловит: валидность проверяется только у активного черновика — набор уходит в POST,
    /// а кейс с названием из пробелов роняет сохранение уже после него.
    @Test func saveDraftWithBlankCaseTitleSendsNothingAndKeepsBothDrafts() async {
        let form = CreateFormFixture()
        form.model.creatingSuite.title = "Suite"
        form.model.creatingTestCase.title = " \n "
        let error = await thrownNetError { try await form.controller.saveDraft() }
        #expect(invalidRequestMessage(error) == "The drafts cannot be saved")
        #expect(form.network.operations.isEmpty)
        #expect(form.created.count == 0)
        #expect(form.model.suiteHasUnsavedChanges && form.model.caseHasUnsavedChanges)
        #expect(!form.controller.isSavingDraft && form.closeIsEnabled)
    }

    // MARK: - saveDraft формы создания проекта

    /// Ловит: колбэк закрытия формы (`createdCallback` + `dismiss`) не подменяется на время `saveDraft`
    /// и форма закрывается из-под `ProjectSwitchGuard`; колбэк не восстанавливается после сохранения.
    @Test func projectSaveDraftSuppressesTheCloseCallbackAndRestoresIt() async throws {
        let network = FormDraftNetwork()
        network.responseBody = #"{"status":true,"result":{"code":"NEW"}}"#
        let model = CreatingProjectViewModel(network: network, session: SessionContext(ownerID: "owner"))
        var created = 0
        let controller = CreatingProjectViewController(viewModel: model, createdCallback: { created += 1 })
        controller.loadViewIfNeeded()
        model.creatingProject.title = "New project"
        model.creatingProject.code = "NEW"
        try await controller.saveDraft()
        #expect(network.operations == [.createProject])
        #expect(model.isEntityWasCreated && !model.hasUnsavedChanges)
        #expect(created == 0)
        model.creatingFinishCallback()
        #expect(created == 1)
        // Колбэк держит контроллер слабо: без этого он мог бы освободиться до вызова.
        withExtendedLifetime(controller) {}
    }

    /// Ловит: удалён guard `isEntityWasCreated` в `saveDraft` — невалидный изменённый черновик
    /// (код из пробелов) считается сохранённым, `ProjectSwitchGuard` пропускает уход;
    /// колбэк закрытия не восстанавливается после ошибки.
    @Test func projectSaveDraftRejectsInvalidChangedDraftWithoutPosting() async {
        let network = FormDraftNetwork()
        let model = CreatingProjectViewModel(network: network, session: SessionContext(ownerID: "owner"))
        var created = 0
        let controller = CreatingProjectViewController(viewModel: model, createdCallback: { created += 1 })
        controller.loadViewIfNeeded()
        model.creatingProject.title = "Title"
        model.creatingProject.code = "   "
        #expect(model.hasUnsavedChanges)
        let error = await thrownNetError { try await controller.saveDraft() }
        #expect(invalidRequestMessage(error) == "Create failed")
        #expect(network.operations.isEmpty)
        #expect(model.hasUnsavedChanges && !model.isEntityWasCreated)
        #expect(created == 0)
        model.creatingFinishCallback()
        #expect(created == 1)
        withExtendedLifetime(controller) {}
    }

}

@MainActor
private func lastPayload(of network: FormDraftNetwork) throws -> [String: Any] {
    let body = try #require(network.capturedBodies.last)
    return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
}

/// Вызывает операцию и возвращает брошенную `NetError`; другая ошибка или успех дают `nil`.
@MainActor
private func thrownNetError(_ operation: () async throws -> Void) async -> API.NetError? {
    do { try await operation() } catch { return error as? API.NetError }
    return nil
}

private func invalidRequestMessage(_ error: API.NetError?) -> String? {
    guard case .invalidRequest(let message)? = error else { return nil }
    return message
}

/// Состояние на MainActor (тест читает `release`, `beforeResponse` меняет сессию);
/// методы протокола `nonisolated`, чтобы `T.Type` не пересекал границу акторов.
@MainActor
private final class FormDraftNetwork: NetworkManager {
    var methods: [API.HTTPMethod] = []
    /// Операции запросов по порядку отправки.
    var operations: [API.Operation] = []
    /// Ошибка на запросе с этим номером (с 1); остальные запросы идут по общему сценарию.
    var failure: (request: Int, error: API.NetError)?
    var capturedBodies: [Data] = []
    var error: API.NetError?
    var shouldSuspend = false
    var beforeResponse: (() -> Void)?
    var release: CheckedContinuation<Void, Never>?
    var responseBody = #"{"status":true,"result":{"id":1}}"#

    nonisolated func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem],
        with data: Encodable?,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        var body: Data?
        if let data { body = try API.encodeBody(data) }
        let reply = try await respond(operation: operation, body: body)
        return try API.decodeResponse(from: Data(reply.utf8), as: modelType)
    }

    /// Записывает запрос и его операцию, при `shouldSuspend` ждёт `release`, затем вызывает `beforeResponse`
    /// и отдаёт тело ответа `responseBody`.
    private func respond(operation: API.Operation, body: Data?) async throws(API.NetError) -> String {
        methods.append(operation.httpMethod)
        operations.append(operation)
        if let body { capturedBodies.append(body) }
        if shouldSuspend { await withCheckedContinuation { release = $0 } }
        beforeResponse?()
        if let failure, failure.request == operations.count { throw failure.error }
        if let error { throw error }
        return responseBody
    }

    nonisolated func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T { throw .invalidURL }
    nonisolated func auth(by token: String) async throws -> Bool { true }
}

private final class CreatedCounter { var count = 0 }

/// Загруженная форма создания набора и кейса с фейковой сетью, счётчиком `onEntityCreated`
/// и заглушкой выбора родителя.
@MainActor
private final class CreateFormFixture {
    let network: FormDraftNetwork
    let created = CreatedCounter()
    let model: EntityCreationViewModel
    let controller: CreateSuiteOrCaseViewController

    init() {
        let network = FormDraftNetwork()
        let session = SessionContext(ownerID: "owner")
        let counter = created
        let model = TestDependencies.creator(projectCode: "A", network: network, session: session)
        self.network = network
        self.model = model
        controller = CreateSuiteOrCaseViewController(
            viewModel: model,
            parentCatalog: TestDependencies.picker(projectCode: "A", session: session),
            makeParentPicker: { _, _, _ in UIViewController() },
            onEntityCreated: { counter.count += 1 }
        )
        controller.loadViewIfNeeded()
    }

    /// `closeItem` приватный: состояние блокировки формы читается через левую кнопку навигации.
    var closeIsEnabled: Bool { controller.navigationItem.leftBarButtonItem?.isEnabled == true }
}
