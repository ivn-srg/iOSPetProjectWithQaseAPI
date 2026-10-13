@testable import QaseAPIProj
import Testing

@MainActor
private final class DraftFixture: ProjectDraft {
    var hasUnsavedChanges = true
    var canSaveDraft = true
    var isSavingDraft = false
    var saves = 0
    var discards = 0
    var shouldFail = false
    func saveDraft() async throws {
        if shouldFail { throw API.NetError.invalidRequest("fixture") }
        saves += 1
        hasUnsavedChanges = false
    }

    func discardDraft() { discards += 1
        hasUnsavedChanges = false }
}

@Suite @MainActor
struct ProjectSwitchTests {
    @Test func busyCleanParticipantBlocksSaveAndDiscard() async throws {
        let busy = DraftFixture(), changed = DraftFixture()
        busy.hasUnsavedChanges = false
        busy.isSavingDraft = true
        #expect(try await !ProjectSwitchGuard().resolve([busy, changed], decision: .discard))
        #expect(try await !ProjectSwitchGuard().resolve([busy, changed], decision: .save))
        #expect(changed.discards == 0 && changed.saves == 0 && changed.hasUnsavedChanges)
    }

    @Test func cancelPreservesAllDrafts() async throws {
        let first = DraftFixture(), second = DraftFixture()
        let allowed = try await ProjectSwitchGuard().resolve([first, second], decision: .stay)
        #expect(!allowed)
        #expect(first.hasUnsavedChanges && second.hasUnsavedChanges)
        #expect(first.saves == 0 && second.discards == 0)
    }

    @Test func saveFailureKeepsRemainingDrafts() async throws {
        let first = DraftFixture(), second = DraftFixture(), third = DraftFixture()
        second.shouldFail = true
        do {
            _ = try await ProjectSwitchGuard().resolve([first, second, third], decision: .save)
            Issue.record("A failed save must prevent switching")
        } catch {
            #expect(first.saves == 1)
            #expect(second.hasUnsavedChanges && third.hasUnsavedChanges)
            #expect(third.saves == 0)
        }
    }

    @Test func invalidDraftPreventsAnySave() async throws {
        let first = DraftFixture(), second = DraftFixture()
        second.canSaveDraft = false
        #expect(try await !ProjectSwitchGuard().resolve([first, second], decision: .save))
        #expect(first.saves == 0)
    }

    @Test func discardIsExplicitAndAppliesToAllDrafts() async throws {
        let drafts = [DraftFixture(), DraftFixture()]
        #expect(try await ProjectSwitchGuard().resolve(drafts, decision: .discard))
        #expect(drafts.allSatisfy { !$0.hasUnsavedChanges && $0.discards == 1 })
    }
}
