import Foundation
@testable import QaseAPIProj
import Testing
import UIKit

@Suite @MainActor
struct DesignTokenTests {
    @Test func primaryButtonWhiteTextMeetsContrastInBothThemes() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            for color in [AppTheme.Palette.buttonStart, AppTheme.Palette.buttonEnd] {
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                #expect(color.resolvedColor(with: traits).getRed(
                    &red,
                    green: &green,
                    blue: &blue,
                    alpha: &alpha
                ))
                let shade = 1 - AppTheme.Palette.buttonContrastOverlay
                let components = [Double(red) * shade, Double(green) * shade, Double(blue) * shade].map {
                    $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4)
                }
                let luminance = components[0] * 0.2126 + components[1] * 0.7152 + components[2] * 0.0722
                #expect(1.05 / (luminance + 0.05) >= 4.5)
            }
        }
    }
}

struct DomainSerializationRegressionTests {
    @Test func fieldEnumsEncodeServerIntegers() throws {
        func check<T: Codable & Equatable>(_ values: [T], ids: [Int]) throws {
            for (value, id) in zip(values, ids) {
                let data = try JSONEncoder().encode(value)
                #expect(try JSONDecoder().decode(Int.self, from: data) == id)
                #expect(try JSONDecoder().decode(T.self, from: data) == value)
            }
        }
        try check(Severity.allCases, ids: Array(0 ... 6))
        try check(Status.allCases, ids: Array(0 ... 2))
        try check(Priority.allCases, ids: Array(0 ... 3))
        try check(Behavior.allCases, ids: Array(0 ... 3))
        try check(Types.allCases, ids: Array(0 ... 10))
        try check(Layer.allCases, ids: Array(0 ... 2))
        try check(AutomationStatus.allCases, ids: Array(0 ... 2))
    }

    @Test func unknownFieldIDsKeepExistingFallbacks() throws {
        let data = Data("999".utf8)
        let decoder = JSONDecoder()
        #expect(try decoder.decode(Severity.self, from: data) == .nothing)
        #expect(try decoder.decode(Status.self, from: data) == .actual)
        #expect(try decoder.decode(Priority.self, from: data) == .nothing)
        #expect(try decoder.decode(Behavior.self, from: data) == .nothing)
        #expect(try decoder.decode(Types.self, from: data) == .other)
        #expect(try decoder.decode(Layer.self, from: data) == .e2e)
        #expect(try decoder.decode(AutomationStatus.self, from: data) == .manual)
    }

    @Test func stableStepIdentityDoesNotHideContentChanges() {
        func step(_ action: String, children: [StepsInTestCase] = []) -> StepsInTestCase {
            StepsInTestCase(
                hash: "same",
                position: 1,
                sharedStepHash: nil,
                sharedStepNestedHash: nil,
                attachments: [],
                action: action,
                expectedResult: "result",
                data: nil,
                steps: children
            )
        }
        #expect(step("before") != step("after"))
        #expect(step("parent", children: [step("before")]) != step("parent", children: [step("after")]))
        #expect(Set([step("before"), step("after")]).count == 2)
        #expect(Set([step("same"), step("same")]).count == 1)
    }

    @Test func caseRequestKeepsIntegerFieldsAndExplicitRoot() throws {
        var draft = TestCaseEntity.empty
        draft.title = "Regression"
        draft.suiteId = nil
        draft.priority = .medium
        draft.isFlaky = true
        let data = try JSONEncoder().encode(EncodableTestCase(testCase: draft))
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["priority"] as? Int == 2)
        #expect(json["is_flaky"] as? Int == 1)
        #expect(json["suite_id"] is NSNull)
    }
}
