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
    @Test func everyFieldEnumMatchesServerSystemFieldOptionsByIDAndTitle() throws {
        try checkFieldEnum(Severity.self, slug: "severity", make: { Severity($0) })
        try checkFieldEnum(Priority.self, slug: "priority", make: { Priority($0) })
        try checkFieldEnum(Status.self, slug: "status", make: { Status($0) })
        try checkFieldEnum(AutomationStatus.self, slug: "automation", make: { AutomationStatus($0) })
        try checkFieldEnum(Behavior.self, slug: "behavior", make: { Behavior($0) })
        try checkFieldEnum(Layer.self, slug: "layer", make: { Layer($0) })
        try checkFieldEnum(Types.self, slug: "type", make: { Types($0) })
    }

    @Test func unknownFieldIDsFallBackToNotSetOrServerDefault() throws {
        let data = Data("999".utf8)
        let decoder = JSONDecoder()
        #expect(try decoder.decode(Severity.self, from: data) == .nothing)
        #expect(try decoder.decode(Status.self, from: data) == .actual)
        #expect(try decoder.decode(Priority.self, from: data) == .nothing)
        #expect(try decoder.decode(Behavior.self, from: data) == .nothing)
        #expect(try decoder.decode(Types.self, from: data) == .other)
        #expect(try decoder.decode(Layer.self, from: data) == .nothing)
        #expect(try decoder.decode(AutomationStatus.self, from: data) == .manual)
    }

    @Test func newCaseDefaultsMatchServerIsDefaultOptions() throws {
        let empty = TestCaseEntity.empty
        let severity = try defaultOptionID("severity")
        let priority = try defaultOptionID("priority")
        let type = try defaultOptionID("type")
        let layer = try defaultOptionID("layer")
        let behavior = try defaultOptionID("behavior")
        let automation = try defaultOptionID("automation")
        let status = try defaultOptionID("status")
        #expect(empty.severity.apiValue == severity)
        #expect(empty.priority.apiValue == priority)
        #expect(empty.type.apiValue == type)
        #expect(empty.layer.apiValue == layer)
        #expect(empty.behavior.apiValue == behavior)
        #expect(empty.automation.apiValue == automation)
        #expect(empty.status.apiValue == status)
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

/// Якорь для `Bundle(for:)`: наборы Swift Testing — структуры, а класс приложения дал бы бандл приложения.
private final class TestBundleToken {}

private struct SystemFieldsResponse: Decodable {
    struct Field: Decodable {
        let slug: String
        let options: [Option]?
    }

    struct Option: Decodable {
        let id: Int
        let title: String
        let isDefault: Bool

        enum CodingKeys: String, CodingKey {
            case id, title
            case isDefault = "is_default"
        }
    }

    let result: [Field]
}

private func systemFieldOptions(_ slug: String) throws -> [SystemFieldsResponse.Option] {
    let url = try #require(Bundle(for: TestBundleToken.self).url(forResource: "system_field", withExtension: "json"))
    let response = try JSONDecoder().decode(SystemFieldsResponse.self, from: Data(contentsOf: url))
    let field = try #require(response.result.first { $0.slug == slug })
    return try #require(field.options)
}

private func defaultOptionID(_ slug: String) throws -> Int {
    let defaults = try systemFieldOptions(slug).filter(\.isDefault)
    #expect(defaults.count == 1)
    return try #require(defaults.first).id
}

/// Сверяет enum с опциями поля сервера: биекция по id, `rawValue` == `title`, кодирование туда и обратно.
private func checkFieldEnum<T: CaseIterable & Codable & Equatable & RawRepresentable>(
    _ type: T.Type,
    slug: String,
    make: (Int) -> T
) throws where T.RawValue == String {
    let options = try systemFieldOptions(slug)
    let apiValues = try T.allCases.map { try JSONDecoder().decode(Int.self, from: JSONEncoder().encode($0)) }
    #expect(T.allCases.count == options.count, "\(slug): число case не равно числу опций сервера")
    #expect(Set(apiValues) == Set(options.map(\.id)), "\(slug): id case не совпадают с id опций")
    for option in options {
        let value = make(option.id)
        let data = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(Int.self, from: data) == option.id, "\(slug): \(option.title)")
        #expect(try JSONDecoder().decode(T.self, from: data) == value, "\(slug): \(option.title)")
        #expect(value.rawValue == option.title, "\(slug): rawValue не равен title опции \(option.id)")
    }
}
