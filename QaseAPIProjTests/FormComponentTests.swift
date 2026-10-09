import Foundation
import UIKit
import Testing
@testable import QaseAPIProj

struct FormComponentTests {
    @Test func insertionAtLimitKeepsTrailingTextAndCaret() throws {
        let text = String(repeating: "a", count: 498) + "XY"
        let edit = try #require(FormTextInputPolicy.replacing(text, range: NSRange(location: 498, length: 0), with: "new"))
        #expect(edit.text == text)
        #expect(edit.selection == NSRange(location: 498, length: 0))
    }

    @Test func pasteInMiddlePreservesSuffix() throws {
        let text = String(repeating: "a", count: 495) + "END"
        let edit = try #require(FormTextInputPolicy.replacing(text, range: NSRange(location: 495, length: 0), with: "12345"))
        #expect(edit.text == String(repeating: "a", count: 495) + "12END")
        #expect(edit.selection == NSRange(location: 497, length: 0))
    }

    @Test func largeClipboardKeepsSuffixAndInsertionCaret() throws {
        let text = String(repeating: "a", count: 495) + "END"
        let clipboard = String(repeating: "x", count: 100_000)
        let edit = try #require(FormTextInputPolicy.replacing(text, range: NSRange(location: 495, length: 0), with: clipboard))
        #expect(edit.text == String(repeating: "a", count: 495) + "xxEND")
        #expect(edit.text.count == 500)
        #expect(edit.selection == NSRange(location: 497, length: 0))
    }

    @Test func joiningCombiningMarkDoesNotConsumeExtraCharacter() throws {
        let text = String(repeating: "a", count: 499) + "e"
        let edit = try #require(FormTextInputPolicy.replacing(text, range: NSRange(location: 500, length: 0), with: "\u{301}XYZ"))
        #expect(edit.text == String(repeating: "a", count: 499) + "e\u{301}")
        #expect(edit.text.count == 500)
        #expect(edit.selection == NSRange(location: 501, length: 0))
    }

    @Test func replacementReusesSelectedCharacterCapacity() throws {
        let text = String(repeating: "a", count: 499) + "Z"
        let edit = try #require(FormTextInputPolicy.replacing(text, range: NSRange(location: 497, length: 2), with: "1234"))
        #expect(edit.text == String(repeating: "a", count: 497) + "12Z")
        #expect(edit.selection == NSRange(location: 499, length: 0))
    }

    @Test func characterLimitCountsExtendedGraphemes() throws {
        let emoji = "👨‍👩‍👧‍👦"
        let text = String(repeating: emoji, count: 499)
        let edit = try #require(FormTextInputPolicy.replacing(text, range: NSRange(location: text.utf16.count, length: 0), with: emoji + "X"))
        #expect(edit.text.count == 500)
        #expect(edit.text == String(repeating: emoji, count: 500))
        #expect(edit.selection.location == edit.text.utf16.count)
    }

    @Test func deletionAndInvalidUTF16RangesAreHandled() throws {
        let edit = try #require(FormTextInputPolicy.replacing("ABC", range: NSRange(location: 1, length: 1), with: ""))
        #expect(edit.text == "AC")
        #expect(edit.selection == NSRange(location: 1, length: 0))
        #expect(FormTextInputPolicy.replacing("ABC", range: NSRange(location: 4, length: 1), with: "X") == nil)
        #expect(FormTextInputPolicy.replacing("😀", range: NSRange(location: 1, length: 1), with: "X") == nil)
    }

    @Test func committedCompositionTruncatesOnceAndClampsSelection() {
        let text = String(repeating: "é", count: 502)
        let edit = FormTextInputPolicy.committed(text, selection: NSRange(location: 502, length: 0))
        #expect(edit.text.count == 500)
        #expect(edit.selection == NSRange(location: 500, length: 0))
    }
}

@Suite @MainActor
struct FormMarkerTests {
    @Test func onlyPriorityAndSeverityHaveMarkers() {
        for field in [FieldType.status, .behavior, .type, .layer, .automation] {
            for id in 0...10 {
                #expect(CustomSelectableView.markerColor(for: field, id: id) == nil)
            }
        }
        for field in [FieldType.priority, .severity] {
            #expect(CustomSelectableView.markerColor(for: field, id: nil) == nil)
            #expect(CustomSelectableView.markerColor(for: field, id: 0) == nil)
        }
    }

    @Test func markersUseSemanticColorsInBothThemes() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            #expect(CustomSelectableView.markerColor(for: .priority, id: 1)?.resolvedColor(with: traits) == AppTheme.Palette.warning.resolvedColor(with: traits))
            #expect(CustomSelectableView.markerColor(for: .priority, id: 2)?.resolvedColor(with: traits) == AppTheme.Palette.info.resolvedColor(with: traits))
            #expect(CustomSelectableView.markerColor(for: .priority, id: 3)?.resolvedColor(with: traits) == AppTheme.Palette.secondaryText.resolvedColor(with: traits))
            #expect(CustomSelectableView.markerColor(for: .severity, id: 2)?.resolvedColor(with: traits) == AppTheme.Palette.danger.resolvedColor(with: traits))
            #expect(CustomSelectableView.markerColor(for: .severity, id: 4)?.resolvedColor(with: traits) == AppTheme.Palette.info.resolvedColor(with: traits))
            #expect(CustomSelectableView.markerColor(for: .severity, id: 6)?.resolvedColor(with: traits) == AppTheme.Palette.success.resolvedColor(with: traits))
        }
    }
}

@Suite @MainActor
struct FormSelectionTests {
    @Test func focusAndBlurKeepUntouchedLongServerTextAndCleanDraft() throws {
        var original = TestCaseEntity.empty
        original.title = "Loaded case"
        original.description = String(repeating: "x", count: 900)
        let model = DetailTabbarControllerViewModel(reference: .init(projectCode: "A", caseID: 1),
            session: SessionContext(ownerID: "owner"))
        model.testCase = original
        model.changedTestCase = original
        let field = GeneralCaseTextField(textType: .description, textViewValue: original.description,
            detailVM: model, style: .entityForm)
        let input = try #require(descendants(of: field).compactMap { $0 as? UITextView }.first)
        field.textViewDidBeginEditing(input)
        field.textViewDidEndEditing(input)
        #expect(input.text == original.description)
        #expect(model.changedTestCase == original)
        #expect(!model.hasUnsavedChanges)
    }

    @Test func verticalValueMarkerStaysWithTextAfterTraitChange() throws {
        let model = FormSelectionModel()
        var draft = TestCaseEntity.empty
        draft.severity = .critical
        model.changedTestCase = draft
        let control = CustomSelectableView(textFieldType: .severity, detailCaseVM: model)
        control.frame = CGRect(x: 0, y: 0, width: 180, height: 140)
        control.setNeedsLayout()
        control.layoutIfNeeded()
        let value = try #require(descendants(of: control).compactMap { $0 as? UILabel }.first { $0.text == Severity.critical.localized })
        let marker = try #require(descendants(of: control).first {
            $0.backgroundColor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)) ==
                AppTheme.Palette.danger.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        })
        let valueFrame = value.convert(value.bounds, to: control)
        let markerFrame = marker.convert(marker.bounds, to: control)
        #expect(markerFrame.minX >= valueFrame.maxX)
        #expect(markerFrame.minX - valueFrame.maxX <= 8)
        let intrinsicWidth = value.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)).width
        #expect(value.bounds.width <= intrinsicWidth + 1)
        control.traitCollectionDidChange(nil)
        control.layoutIfNeeded()
        #expect(control.accessibilityValue == Severity.critical.localized)
    }

    private func descendants(of view: UIView) -> [UIView] {
        view.subviews.flatMap { [$0] + descendants(of: $0) }
    }

    @Test func selectedValueAndMenuUseUnsavedDraft() {
        let model = FormSelectionModel()
        var original = TestCaseEntity.empty
        original.priority = .low
        var draft = original
        draft.priority = .high
        model.testCase = original
        model.changedTestCase = draft
        let field = CustomSelectableView(textFieldType: .priority, detailCaseVM: model)
        #expect(field.accessibilityValue == Priority.high.localized)
        #expect(field.menu?.children.compactMap { $0 as? UIAction }.filter { $0.state == .on }.map(\.title) == [Priority.high.localized])
        draft.priority = .medium
        model.changedTestCase = draft
        field.updateSelectedValue()
        #expect(field.accessibilityValue == Priority.medium.localized)
        #expect(field.menu?.children.compactMap { $0 as? UIAction }.filter { $0.state == .on }.map(\.title) == [Priority.medium.localized])
        field.setEditingEnabled(false)
        #expect(!field.isEnabled)
    }
}

@MainActor
private final class FormSelectionModel: UpdatableEntityProtocol {
    var testCase: TestCaseEntity?
    var changedTestCase: TestCaseEntity?

    func updateValue<T>(for field: FieldType, value: T) {
        guard field == .priority, let id = value as? Int else { return }
        changedTestCase?.priority = Priority(id)
    }
}
