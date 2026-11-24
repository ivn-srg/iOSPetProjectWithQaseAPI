import Foundation
@testable import QaseAPIProj
import RealmSwift
import Testing

/// Кейс в форме ответа Qase по схеме `TestCase.yaml`: объекты вместо строк в коллекциях,
/// шаги без `hash` и `position`, нет `suite_id`, `member_id` и `links`.
@MainActor
struct TestCaseDecodingTests {
    private static let schemaCaseJSON = #"""
    {
      "id": 42, "position": 3, "title": "Schema case",
      "description": null, "preconditions": null, "postconditions": null,
      "severity": 4, "priority": 1, "type": 1, "layer": 0, "is_flaky": 0, "behavior": 1,
      "automation": 0, "isManual": true, "isToBeAutomated": false, "status": 0,
      "milestone_id": null,
      "custom_fields": [{"id": 1, "value": "x"}],
      "attachments": [{"size": 10, "mime": "image/png", "filename": "a.png", "url": "https://example.invalid/a.png"}],
      "steps_type": "classic",
      "params": {"browser": ["chrome"]},
      "parameters": [],
      "tags": [{"title": "smoke", "internal_id": 5}],
      "author_id": 2,
      "created_at": "2026-11-01T10:00:00+00:00", "updated_at": "2026-11-02T10:00:00+00:00",
      "steps": [
        {
          "action": "Open the form", "expected_result": "Form is shown", "data": "input",
          "shared_step_hash": null,
          "attachments": [{"size": 5, "mime": "image/png", "filename": "s.png", "url": "https://example.invalid/s.png"}],
          "steps": [
            {
              "action": "Nested action", "expected_result": "Nested result", "data": null,
              "shared_step_hash": null, "attachments": [], "steps": []
            }
          ]
        },
        {
          "action": "Submit the form", "expected_result": "Saved", "data": null,
          "shared_step_hash": null, "steps": []
        }
      ]
    }
    """#

    private func decodeCase() throws -> TestCaseEntity {
        try JSONDecoder().decode(TestCaseEntity.self, from: Data(Self.schemaCaseJSON.utf8))
    }

    @Test func caseWithObjectCollectionsAndNoSuiteIDDecodesInsteadOfFailingOnTypeMismatch() throws {
        let entity = try decodeCase()
        #expect(entity.id == 42 && entity.title == "Schema case" && entity.authorId == 2)
        #expect(entity.tags.isEmpty)
        #expect(entity.attachments.isEmpty)
        #expect(entity.customFields.isEmpty)
        #expect(entity.params.isEmpty)
        #expect(entity.links.isEmpty)
        #expect(entity.suiteId == nil)
        #expect(entity.memberId == 0)
        #expect(entity.severity == .normal && entity.priority == .high && entity.automation == .manual)
    }

    @Test func stepsWithoutHashAndPositionKeepSourceOrderAndOneBasedPositions() throws {
        let entity = try decodeCase()
        #expect(entity.steps.map(\.action) == ["Open the form", "Submit the form"])
        #expect(entity.steps.map(\.position) == [1, 2])
        #expect(entity.steps.first?.attachments.isEmpty == true)
        #expect(entity.steps.first?.steps?.map(\.action) == ["Nested action"])
        #expect(entity.steps.first?.steps?.first?.position == 1)
    }

    @Test func stepsWithoutHashGetNonEmptyDistinctKeysIncludingNestedSteps() throws {
        let entity = try decodeCase()
        let nested = try #require(entity.steps.first?.steps?.first)
        let hashes = entity.steps.map(\.hash) + [nested.hash]
        #expect(hashes.allSatisfy { !$0.isEmpty })
        #expect(Set(hashes).count == 3)
    }

    @Test func stepKeysAreIdenticalAcrossRepeatedDecodingOfTheSameResponse() throws {
        func hashes(_ entity: TestCaseEntity) -> [String] {
            entity.steps.flatMap { [$0.hash] + ($0.steps ?? []).map(\.hash) }
        }
        let first = hashes(try decodeCase())
        let second = hashes(try decodeCase())
        #expect(first.count == 3 && first == second)
    }

    @Test func tolerantlyDecodedCaseReadsBackFromRealmUnchanged() throws {
        let session = SessionContext(ownerID: "owner")
        let dao = RealmManager(configuration: .init(inMemoryIdentifier: UUID().uuidString), session: session)
        let entity = try decodeCase()
        let reference = TestCaseReference(projectCode: "A", caseID: entity.id)
        #expect(dao.saveTestCase(entity, reference: reference, stamp: session.capture()))
        #expect(dao.getTestCase(reference: reference) == entity)
    }
}
