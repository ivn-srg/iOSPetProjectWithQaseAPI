import Foundation
@testable import QaseAPIProj
import Testing
import UIKit

@Suite(.timeLimit(.minutes(1))) @MainActor
struct FormSaveDraftTests {
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
        form.network.respond = failing(form.network, request: 2, with: .timeout)
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
        form.network.respond = failing(form.network, request: 1, with: .timeout)
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
        let network = draftNetwork()
        network.respond = ScriptedNetwork.body(#"{"status":true,"result":{"code":"NEW"}}"#)
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
        let network = draftNetwork()
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

/// Успешный ответ создания по умолчанию для сети форм.
private let draftReply = #"{"status":true,"result":{"id":1}}"#

/// Сеть форм на общем ядре: по умолчанию успешный ответ `draftReply`.
@MainActor
private func draftNetwork() -> ScriptedNetwork {
    ScriptedNetwork(respond: ScriptedNetwork.body(draftReply))
}

/// Ошибка на запросе с номером `request` (с 1); остальные — успешный ответ `draftReply`.
@MainActor
private func failing(
    _ network: ScriptedNetwork,
    request: Int,
    with error: API.NetError
) -> ScriptedNetwork.Responder {
    { [unowned network] _ in
        network.requests.count == request ? .failure(error) : .success(Data(draftReply.utf8))
    }
}

private final class CreatedCounter { var count = 0 }

/// Загруженная форма создания набора и кейса с фейковой сетью, счётчиком `onEntityCreated`
/// и заглушкой выбора родителя.
@MainActor
private final class CreateFormFixture {
    let network: ScriptedNetwork
    let created = CreatedCounter()
    let model: EntityCreationViewModel
    let controller: CreateSuiteOrCaseViewController

    init() {
        let network = draftNetwork()
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
