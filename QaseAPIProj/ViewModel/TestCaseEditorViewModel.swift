import Foundation
import UIKit

@MainActor
final class TestCaseEditorViewModel {
    weak var delegate: DetailTestCaseProtocol?
    var testCase: TestCaseEntity? { didSet { delegate?.updateUI() } }
    var changedTestCase: TestCaseEntity? { didSet { if !isPublishing { checkDataChanged() } } }
    var isUploadingSuccess = false { didSet { if isUploadingSuccess { updatingFinishCallback() } } }
    private(set) var isSaving = false { didSet { checkDataChanged() } }
    let reference: TestCaseReference
    var caseUniqueKey: String { reference.cacheKey }
    var caseId: Int { reference.caseID }
    var updatingFinishCallback: () -> Void = {}
    var checkDataChanged: () -> Void = {}
    private let onCacheFailure: () -> Void
    private let network: NetworkManager
    private let dao: TestCaseCaching & HomeCaching
    private let session: SessionContext
    private let stamp: SessionStamp
    private let clock: () -> Date
    private var didRecordView = false
    private var isPublishing = false
    private var saveGeneration = 0

    private func reportCacheWrite(_ accepted: Bool) {
        if !accepted { onCacheFailure() }
    }

    init(
        reference: TestCaseReference,
        network: NetworkManager,
        dao: TestCaseCaching & HomeCaching,
        session: SessionContext,
        clock: @escaping () -> Date = Date.init,
        onCacheFailure: @escaping () -> Void = {}
    ) {
        self.onCacheFailure = onCacheFailure
        self.reference = reference
        self.network = network
        self.dao = dao
        self.session = session
        self
            .stamp = session.capture()
        self.clock = clock
    }

    var isSessionCurrent: Bool { session.isCurrent(stamp) }
    var canSaveChanges: Bool { canSaveDraft && hasUnsavedChanges && isSessionCurrent && !isSaving }
    var hasUnsavedChanges: Bool { testCase != changedTestCase }
    var canSaveDraft: Bool {
        changedTestCase?.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }

    func discardDraft() {
        guard !isSaving, isSessionCurrent else { return }
        changedTestCase = testCase
    }

    /// Кеш показывается сразу, затем кейс сверяется с сервером. Ошибка сверки при показанном кеше не сообщается.
    func fetchCaseDataJSON() async throws(API.NetError) {
        guard session.isCurrent(stamp), !Task.isCancelled else { return }
        let cached = dao.getTestCase(reference: reference)
        if let cached { publish(cached) }
        let generation = saveGeneration
        guard let result = await loadServerCase() else { return }
        switch result {
        case .failure(let error):
            if cached == nil { throw error }
        case .success(let fresh):
            // Сохранение, начатое во время сверки, перечитает кейс само; старый ответ не пишется никуда.
            guard generation == saveGeneration, !isSaving else { return }
            reportCacheWrite(dao.saveTestCase(fresh, reference: reference, stamp: stamp))
            if !hasUnsavedChanges {
                publish(fresh)
                // Первое открытие из кеша записало в историю устаревшую версию.
                if cached != nil { recordRecentView(of: fresh) }
            }
        }
    }

    /// `nil` — сессия сменилась или задача отменена: ответ не применяется.
    private func loadServerCase() async -> Result<TestCaseEntity, API.NetError>? {
        let response: TestCaseModel
        do {
            response = try await network.performRequest(
                for: .getCase,
                pathParameters: casePath,
                queryItems: [],
                with: nil,
                modelType: TestCaseModel.self
            )
        } catch {
            // `performRequest` бросает только `API.NetError`: тип ошибки здесь выводится компилятором.
            guard session.isCurrent(stamp), !Task.isCancelled else { return nil }
            return .failure(error)
        }
        guard session.isCurrent(stamp), !Task.isCancelled else { return nil }
        guard response.status, response.result.id == reference.caseID
        else { return .failure(.invalidRequest("The test case could not be loaded")) }
        return .success(response.result)
    }

    private var casePath: [String: String] {
        ["code": reference.projectCode, "id": String(reference.caseID)]
    }

    private func publish(_ value: TestCaseEntity) {
        guard session.isCurrent(stamp) else { return }
        isPublishing = true
        changedTestCase = value
        testCase = value
        isPublishing = false
        checkDataChanged()
        if !didRecordView {
            recordRecentView(of: value)
            didRecordView = true
        }
    }

    private func recordRecentView(of value: TestCaseEntity) {
        let item = RecentCaseItem(
            reference: reference,
            title: value.title,
            description: value.description,
            priority: value.priority.apiValue,
            automation: value.automation.apiValue,
            viewedAt: clock()
        )
        reportCacheWrite(dao.recordRecentCase(item, stamp: stamp))
    }

    /// PATCH отправляет только изменённые поля, затем кейс перечитывается: ответ PATCH содержит лишь `id`.
    func updateTestCaseData() async throws(API.NetError) {
        guard !isSaving else { throw .invalidRequest("A save is already in progress") }
        isUploadingSuccess = false
        guard isSessionCurrent, !Task.isCancelled, let base = testCase, let draft = changedTestCase,
              canSaveDraft, hasUnsavedChanges else { throw .invalidRequest("The draft cannot be saved") }
        saveGeneration += 1
        isSaving = true
        defer { isSaving = false }
        let payload = TestCaseUpdatePayload(from: base, to: draft)
        var saved = draft
        if !payload.isEmpty {
            let response = try await network.performRequest(
                for: .updateCase,
                pathParameters: casePath,
                queryItems: [],
                with: payload,
                modelType: ServerResponseModel<CreateOrUpdateTestCaseModel>.self
            )
            guard isSessionCurrent,
                  !Task.isCancelled else { throw .invalidRequest("The session is no longer active") }
            guard response.status?.value == true
            else { throw .invalidRequest("The test case could not be saved") }
            // Не удалось перечитать — PATCH уже принят, в кеш идёт черновик.
            if case .success(let fresh)? = await loadServerCase() { saved = fresh }
            guard isSessionCurrent,
                  !Task.isCancelled else { throw .invalidRequest("The session is no longer active") }
        }
        reportCacheWrite(dao.saveTestCase(saved, reference: reference, stamp: stamp))
        recordRecentView(of: saved)
        isPublishing = true
        changedTestCase = saved
        testCase = saved
        isPublishing = false
        checkDataChanged()
        isSaving = false
        isUploadingSuccess = true
    }
}

extension TestCaseEditorViewModel: UpdatableEntityProtocol {
    var formCase: TestCaseEntity? { changedTestCase ?? testCase }
    var formParentID: Int? { formCase?.suiteId }

    func updateValue(for field: FieldType, value: FormFieldValue) {
        guard !isSaving, isSessionCurrent else { return }
        switch field {
        case .title, .description, .precondition, .postcondition:
            guard let value = value.text else { return }

            switch field {
            case .title:
                changedTestCase?.title = value
            case .description:
                changedTestCase?.description = value
            case .precondition:
                changedTestCase?.preconditions = value
            case .postcondition:
                changedTestCase?.postconditions = value
            default: break
            }
        case .severity, .status, .priority, .behavior, .type, .layer, .isFlaky, .automation:

            if field == .isFlaky {
                if let value = value.toggle { changedTestCase?.isFlaky = value }
                return
            }
            guard let intValue = value.selectionID else { return }

            switch field {
            case .severity:
                changedTestCase?.severity = Severity(intValue)
            case .status:
                changedTestCase?.status = Status(intValue)
            case .priority:
                changedTestCase?.priority = Priority(intValue)
            case .behavior:
                changedTestCase?.behavior = Behavior(intValue)
            case .type:
                changedTestCase?.type = Types(intValue)
            case .layer:
                changedTestCase?.layer = Layer(intValue)
            case .automation:
                changedTestCase?.automation = AutomationStatus(intValue)
            default: break
            }
        default: break
        }
    }
}
