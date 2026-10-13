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

    func fetchCaseDataJSON() async throws(API.NetError) {
        guard session.isCurrent(stamp), !Task.isCancelled else { return }
        if let cached = dao.getTestCase(reference: reference) {
            publish(cached)
            return
        }
        guard let url = network.composeURL(
            for: .cases,
            urlComponents: [reference.projectCode, String(reference.caseID)],
            queryItems: nil
        ) else { throw .invalidURL }

        let response = try await network.performRequest(
            with: nil,
            from: url,
            method: .get,
            modelType: TestCaseModel.self
        )
        guard session.isCurrent(stamp), !Task.isCancelled else { return }
        guard response.status,
              response.result.id == reference.caseID
        else { throw .invalidRequest("The test case could not be loaded") }
        reportCacheWrite(dao.saveTestCase(response.result, reference: reference, stamp: stamp))
        publish(response.result)
    }

    private func publish(_ value: TestCaseEntity) {
        guard session.isCurrent(stamp) else { return }
        isPublishing = true
        changedTestCase = value
        testCase = value
        isPublishing = false
        checkDataChanged()
        if !didRecordView {
            let item = RecentCaseItem(
                reference: reference,
                title: value.title,
                description: value.description,
                priority: value.priority.apiValue,
                automation: value.automation.apiValue,
                viewedAt: clock()
            )
            reportCacheWrite(dao.recordRecentCase(item, stamp: stamp))
            didRecordView = true
        }
    }

    func updateTestCaseData() async throws(API.NetError) {
        guard !isSaving else { throw .invalidRequest("A save is already in progress") }
        isUploadingSuccess = false
        guard isSessionCurrent, !Task.isCancelled, let draft = changedTestCase, canSaveDraft,
              hasUnsavedChanges else { throw .invalidRequest("The draft cannot be saved") }
        guard let url = network.composeURL(
            for: .cases,
            urlComponents: [reference.projectCode, String(reference.caseID)],
            queryItems: nil
        ) else { throw .invalidURL }
        isSaving = true
        defer { isSaving = false }
        let response = try await network.performRequest(
            with: draft.dictOfValues,
            from: url,
            method: .patch,
            modelType: ServerResponseModel<CreateOrUpdateTestCaseModel>.self
        )
        guard isSessionCurrent,
              !Task.isCancelled else { throw .invalidRequest("The session is no longer active") }
        guard response.status?.value == true
        else { throw .invalidRequest("The test case could not be saved") }
        reportCacheWrite(dao.saveTestCase(draft, reference: reference, stamp: stamp))
        isPublishing = true
        changedTestCase = draft
        testCase = draft
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
