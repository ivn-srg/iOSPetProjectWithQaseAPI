import SwiftUI
import UIKit

@MainActor
protocol HomeRouting: AnyObject {
    func selectProject(_ project: ProjectSummary)
    func manageProjects()
    func showCases(search: Bool)
    func showSuites()
    func showRuns()
    func showRun(id: Int)
    func showDefects()
    func showCase(reference: TestCaseReference)
}

@MainActor
protocol ProjectDraft: AnyObject {
    var hasUnsavedChanges: Bool { get }
    var canSaveDraft: Bool { get }
    var isSavingDraft: Bool { get }
    func saveDraft() async throws
    func discardDraft()
}

extension ProjectDraft {
    var isSavingDraft: Bool { false }
}

@MainActor
protocol FormDepartureParticipant: ProjectDraft {
    func requestDeparture() async -> Bool
}

@MainActor
enum FormDepartureGuard {
    static func confirm(
        _ draft: ProjectDraft,
        on presenter: UIViewController,
        message: String
    ) async -> Bool {
        guard !draft.isSavingDraft else { return false }
        guard draft.hasUnsavedChanges else { return true }
        guard presenter.presentedViewController == nil else { return false }
        let decision: DraftDecision = await withCheckedContinuation { continuation in
            let alert = UIAlertController(
                title: "Discard changes?".localized,
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Continue editing".localized, style: .cancel) { _ in
                continuation.resume(returning: .stay)
            })
            alert.addAction(UIAlertAction(title: "Discard changes".localized, style: .destructive) { _ in
                continuation.resume(returning: .discard)
            })
            presenter.present(alert, animated: true)
        }
        return (try? await ProjectSwitchGuard().resolve([draft], decision: decision)) == true
    }
}

enum DraftDecision { case save, discard, stay }

@MainActor
struct ProjectSwitchGuard {
    func resolve(_ drafts: [ProjectDraft], decision: DraftDecision) async throws -> Bool {
        guard !drafts.contains(where: \.isSavingDraft) else { return false }
        let dirty = drafts.filter(\.hasUnsavedChanges)
        switch decision {
        case .stay: return false
        case .discard:
            dirty.forEach { $0.discardDraft() }
            return true
        case .save:
            guard dirty.allSatisfy(\.canSaveDraft) else { return false }
            for draft in dirty {
                guard !drafts.contains(where: \.isSavingDraft) else { return false }
                try await draft.saveDraft()
            }
            return true
        }
    }
}

@MainActor
final class ApplicationProjectCoordinator {
    private let store: SelectedProjectStore
    private weak var host: ApplicationNavigationHost?
    private let session: SessionContext
    private var isSwitching = false
    private var isPreparingChange = false

    init(store: SelectedProjectStore, session: SessionContext) {
        self.store = store
        self.session = session
    }

    func attach(_ host: ApplicationNavigationHost) { self.host = host }

    func choose(_ project: ProjectSummary?) async -> Bool {
        guard !isSwitching, project?.code != store.selectedProject?.code else {
            return project?.code == store.selectedProject?.code
        }
        let stamp = session.capture()
        isSwitching = true
        defer { isSwitching = false }
        guard await prepareForChange(), session.isCurrent(stamp) else { return false }
        store.commit(project)
        UISelectionFeedbackGenerator().selectionChanged()
        return true
    }

    func prepareForChange(
        in controller: UIViewController? = nil,
        switchingProject: Bool = true
    ) async -> Bool {
        guard let shell = host?.navigationRoot, !isPreparingChange else { return false }
        let drafts = participants(in: controller ?? shell)
        guard !drafts.contains(where: \.isSavingDraft) else { return false }
        let dirty = drafts.filter(\.hasUnsavedChanges)
        guard !dirty.isEmpty else { return true }
        let stamp = session.capture()
        isPreparingChange = true
        defer { isPreparingChange = false }
        let decision = await decisionForDrafts(dirty, from: shell, switchingProject: switchingProject)
        guard session.isCurrent(stamp), !drafts.contains(where: \.isSavingDraft) else { return false }
        do {
            return try await ProjectSwitchGuard().resolve(drafts, decision: decision)
        } catch {
            let presenter = topPresenter(shell)
            UIAlertController.showSimpleAlert(
                on: presenter,
                title: "Error".localized,
                message: "Could not save changes. The project was not changed."
                    .localized
            )
            return false
        }
    }

    private func participants(in controller: UIViewController) -> [ProjectDraft] {
        var result: [ProjectDraft] = []
        if let draft = controller as? ProjectDraft { result.append(draft) }
        for child in controller.children { result += participants(in: child) }
        if let presented = controller.presentedViewController { result += participants(in: presented) }
        var seen = Set<ObjectIdentifier>()
        return result.filter { seen.insert(ObjectIdentifier($0)).inserted }
    }

    private func topPresenter(_ controller: UIViewController) -> UIViewController {
        if let presented = controller.presentedViewController { return topPresenter(presented) }
        if let tab = controller as? UITabBarController, let selected = tab.selectedViewController {
            return topPresenter(selected)
        }
        if let nav = controller as? UINavigationController, let visible = nav.visibleViewController {
            return topPresenter(visible)
        }
        return controller
    }

    private func decisionForDrafts(
        _ drafts: [ProjectDraft],
        from shell: UIViewController,
        switchingProject: Bool
    ) async -> DraftDecision {
        await withCheckedContinuation { continuation in
            let alert = UIAlertController(
                title: "Unsaved changes".localized,
                message: (switchingProject ?
                    "Save changes before switching projects?" :
                    "Save changes before leaving this screen?").localized,
                preferredStyle: .alert
            )
            let save = UIAlertAction(
                title: (switchingProject ? "Save and switch" : "Save and continue").localized,
                style: .default
            ) { _ in
                continuation.resume(returning: .save)
            }
            save.isEnabled = drafts.allSatisfy(\.canSaveDraft)
            alert.addAction(save)
            alert.addAction(UIAlertAction(
                title: (switchingProject ? "Discard and switch" : "Discard and continue").localized,
                style: .destructive
            ) { _ in
                continuation.resume(returning: .discard)
            })
            alert.addAction(UIAlertAction(title: "Stay".localized, style: .cancel) { _ in
                continuation.resume(returning: .stay)
            })
            if !save.isEnabled {
                alert.message = "Some changes cannot be saved. Stay to finish editing or discard them."
                    .localized
            }
            topPresenter(shell).present(alert, animated: true)
        }
    }
}
