import Foundation
import UIKit

@MainActor
final class DetailTabbarControllerViewModel {
    weak var delegate: DetailTestCaseProtocol?
    var testCase: TestCaseEntity? { didSet { delegate?.updateUI() } }
    var changedTestCase: TestCaseEntity? { didSet { checkDataChanged() } }
    var isUploadingSuccess = false { didSet { if isUploadingSuccess { updatingFinishCallback() } } }
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

    init(reference: TestCaseReference, network: NetworkManager = ApiServiceConfiguration.shared.apiService, dao: HeroDAO? = nil, session: SessionContext? = nil, clock: @escaping () -> Date = Date.init) {
        let session = session ?? .shared
        self.reference = reference; self.network = network; self.dao = dao ?? RealmManager.shared; self.session = session; self.stamp = session.capture(); self.clock = clock
    }
    var hasUnsavedChanges: Bool { testCase != changedTestCase }
    var canSaveDraft: Bool { changedTestCase?.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
    func discardDraft() { changedTestCase = testCase }

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
        testCase = value; changedTestCase = value
        if !didRecordView {
            let item = RecentCaseItem(reference: reference, title: value.title, description: value.description, priority: value.priority.menuItem.id, automation: value.automation.menuItem.id, viewedAt: clock())
            _ = dao.recordRecentCase(item, stamp: stamp)
            didRecordView = true
        }
    }
    func updateTestCaseData() async throws(API.NetError) {
        isUploadingSuccess = false
        guard session.isCurrent(stamp), let draft = changedTestCase, canSaveDraft else { throw .invalidRequest("The draft cannot be saved") }
        guard let url = network.composeURL(for: .cases, urlComponents: [reference.projectCode, String(reference.caseID)], queryItems: nil) else { throw .invalidURL }
        LoadingIndicator.startLoading(); defer { if session.isCurrent(stamp) { LoadingIndicator.stopLoading() } }
        let response = try await network.performRequest(with: draft.dictOfValues, from: url, method: .patch, modelType: ServerResponseModel<CreateOrUpdateTestCaseModel>.self)
        guard session.isCurrent(stamp) else { return }
        guard response.status?.value == true else { throw .invalidRequest("The test case could not be saved") }
        _ = dao.saveTestCase(draft, reference: reference, stamp: stamp)
        testCase = draft; changedTestCase = draft; isUploadingSuccess = true
    }
}

extension DetailTabbarControllerViewModel: UpdatableEntityProtocol {
    func updateValue<T>(for field: FieldType, value: T) {
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
            
            let intValue = value as? Int
            
            switch field {
            case .severity:
                changedTestCase?.severity = Severity(intValue ?? 0)
            case .status:
                changedTestCase?.status = Status(intValue ?? 0)
            case .priority:
                changedTestCase?.priority = Priority(intValue ?? 0)
            case .behavior:
                changedTestCase?.behavior = Behavior(intValue ?? 0)
            case .type:
                changedTestCase?.type = Types(intValue ?? 0)
            case .layer:
                changedTestCase?.layer = Layer(intValue ?? 0)
            case .isFlaky:
                changedTestCase?.isFlaky = value as? Bool ?? false
            case .automation:
                changedTestCase?.automation = AutomationStatus(intValue ?? 0)
            default: break
            }
        default: break
        }
    }
}
