import Foundation
import UIKit

@MainActor
final class DetailTabbarControllerViewModel {
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
    private let network: NetworkManager
    private let dao: HeroDAO
    private let session: SessionContext
    private let stamp: SessionStamp
    private let clock: () -> Date
    private var didRecordView = false
    private var isPublishing = false

    init(reference: TestCaseReference, network: NetworkManager = ApiServiceConfiguration.shared.apiService, dao: HeroDAO? = nil, session: SessionContext? = nil, clock: @escaping () -> Date = Date.init) {
        let session = session ?? .shared
        self.reference = reference; self.network = network; self.dao = dao ?? RealmManager.shared; self.session = session; self.stamp = session.capture(); self.clock = clock
    }
    var isSessionCurrent: Bool { session.isCurrent(stamp) }
    var canSaveChanges: Bool { canSaveDraft && hasUnsavedChanges && isSessionCurrent && !isSaving }
    var hasUnsavedChanges: Bool { testCase != changedTestCase }
    var canSaveDraft: Bool { changedTestCase?.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
    func discardDraft() {
        guard !isSaving, isSessionCurrent else { return }
        changedTestCase = testCase
    }

    func fetchCaseDataJSON() async throws(API.NetError) {
        guard session.isCurrent(stamp) else { return }
        if let cached = dao.getTestCase(reference: reference) {
            publish(cached); return
        }
        guard let url = network.composeURL(for: .cases, urlComponents: [reference.projectCode, String(reference.caseID)], queryItems: nil) else { throw .invalidURL }
        LoadingIndicator.startLoading(); defer { if session.isCurrent(stamp) { LoadingIndicator.stopLoading() } }
        let response = try await network.performRequest(with: nil, from: url, method: .get, modelType: TestCaseModel.self)
        guard session.isCurrent(stamp) else { return }
        guard response.status, response.result.id == reference.caseID else { throw .invalidRequest("The test case could not be loaded") }
        _ = dao.saveTestCase(response.result, reference: reference, stamp: stamp)
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
            let item = RecentCaseItem(reference: reference, title: value.title, description: value.description, priority: value.priority.menuItem.id, automation: value.automation.menuItem.id, viewedAt: clock())
            _ = dao.recordRecentCase(item, stamp: stamp)
            didRecordView = true
        }
    }
    func updateTestCaseData() async throws(API.NetError) {
        guard !isSaving else { throw .invalidRequest("A save is already in progress") }
        isUploadingSuccess = false
        guard isSessionCurrent, !Task.isCancelled, let draft = changedTestCase, canSaveDraft, hasUnsavedChanges else { throw .invalidRequest("The draft cannot be saved") }
        guard let url = network.composeURL(for: .cases, urlComponents: [reference.projectCode, String(reference.caseID)], queryItems: nil) else { throw .invalidURL }
        isSaving = true
        LoadingIndicator.startLoading()
        defer { isSaving = false; if isSessionCurrent { LoadingIndicator.stopLoading() } }
        let response = try await network.performRequest(with: draft.dictOfValues, from: url, method: .patch, modelType: ServerResponseModel<CreateOrUpdateTestCaseModel>.self)
        guard isSessionCurrent, !Task.isCancelled else { throw .invalidRequest("The session is no longer active") }
        guard response.status?.value == true else { throw .invalidRequest("The test case could not be saved") }
        _ = dao.saveTestCase(draft, reference: reference, stamp: stamp)
        isPublishing = true
        changedTestCase = draft
        testCase = draft
        isPublishing = false
        checkDataChanged()
        isSaving = false
        isUploadingSuccess = true
    }
}

extension DetailTabbarControllerViewModel: UpdatableEntityProtocol {
    func updateValue<T>(for field: FieldType, value: T) {
        guard !isSaving, isSessionCurrent else { return }
        switch field {
        case .title, .description, .precondition, .postcondition:
            guard let value = value as? String else { return }
            
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
                if let value = value as? Bool { changedTestCase?.isFlaky = value }
                return
            }
            guard let intValue = (value as? Int) ?? (value as? MenuItem)?.id else { return }
            
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
