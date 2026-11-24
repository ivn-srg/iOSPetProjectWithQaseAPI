import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

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
        let network = draftNetwork()
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
        let network = draftNetwork()
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
        network.respond = ScriptedNetwork.failure(.noInternetConnection)
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
        network.respond = ScriptedNetwork.body(draftReply)
        model.creatingEntityIsSuite = false
        try await model.createNewEntity()
        #expect(!model.hasAnyUnsavedChanges && network.methods.count == 3)
    }

    @Test func busyCreateRejectsAnotherRequestAndParentMutation() async throws {
        let network = draftNetwork()
        let model = TestDependencies.creator(
            projectCode: "A",
            network: network,
            session: SessionContext(ownerID: "owner")
        )
        model.creatingSuite.title = "Suite"
        var request: Task<Void, Error>?
        network.holds = { _ in true }
        request = Task { try await model.createNewEntity() }
        await waitForCondition { network.pending > 0 }
        #expect(model.isSaving && !model.canCreate)
        model.selectParent(7, forSuite: true)
        #expect(model.creatingSuite.parentId == nil)
        do { try await model.createNewEntity()
            Issue.record("Busy save must fail") } catch {}
        #expect(network.methods.count == 1)
        network.releaseAll()
        try await request?.value
        #expect(!model.isSaving && !model.suiteHasUnsavedChanges)
    }

    @Test func staleCreateResponseDoesNotPublishSuccessOrConfirmDraft() async throws {
        let session = SessionContext(ownerID: "old")
        let network = draftNetwork()
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
        let network = draftNetwork()
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
        network.respond = ScriptedNetwork.failure(.timeout)
        do { try await model.updateTestCaseData()
            Issue.record("Failed update must preserve draft")
        } catch {}
        #expect(model.changedTestCase == draft && model.testCase == initial)
        #expect(model.changedTestCase?.suiteId == 8)
        #expect(model.canSaveChanges && !model.isUploadingSuccess && !model.isSaving)
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

    @Test func busyEditorDoesNotPatchTwiceAndLateResponseCannotReplaceCache() async throws {
        let session = SessionContext(ownerID: "old")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let network = draftNetwork()
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
        network.holds = { _ in true }
        request = Task { try await model.updateTestCaseData() }
        await waitForCondition { network.pending > 0 }
        #expect(model.isSaving && !model.canSaveChanges)
        do { try await model.updateTestCaseData()
            Issue.record("Busy editor must not patch twice") } catch {}
        #expect(network.methods.count == 1)
        session.activate(ownerID: "new")
        network.releaseAll()
        do { try await request?.value
            Issue.record("Late response must fail") } catch {}
        #expect(!finished && !model.isUploadingSuccess && !model.isSaving)
        #expect(model.testCase?.title == "Original" && model.changedTestCase?.title == "Retained draft")
        #expect(dao.getTestCase(reference: reference) == nil)
        session.activate(ownerID: "old")
        #expect(dao.getTestCase(reference: reference)?.title == "Original")
    }
}

/// Успешный ответ создания по умолчанию для сети форм.
private let draftReply = #"{"status":true,"result":{"id":1}}"#

/// Сеть форм на общем ядре: по умолчанию успешный ответ `draftReply`.
@MainActor
private func draftNetwork() -> ScriptedNetwork {
    ScriptedNetwork(respond: ScriptedNetwork.body(draftReply))
}
