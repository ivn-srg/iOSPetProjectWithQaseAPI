import Foundation
@testable import QaseAPIProj
import Testing
import UIKit

@Suite @MainActor
struct DesignTokenTests {
    private static let themes: [UIUserInterfaceStyle] = [.light, .dark]

    @Test func whiteTextOnDestructiveFillMeetsContrastInBothThemes() {
        for style in Self.themes {
            let fill = Self.rgb(AppTheme.Palette.destructiveFill, style)
            #expect(Self.contrast([1, 1, 1], fill) >= 4.5, "\(style == .dark ? "dark" : "light")")
        }
    }

    @Test func primaryButtonWhiteTextMeetsContrastInBothThemes() {
        for style in Self.themes {
            for color in [AppTheme.Palette.buttonStart, AppTheme.Palette.buttonEnd] {
                let shade = 1 - AppTheme.Palette.buttonContrastOverlay
                let shaded = Self.rgb(color, style).map { $0 * shade }
                #expect(1.05 / (Self.luminance(shaded) + 0.05) >= 4.5)
            }
        }
    }

    /// Пары «текст/фон», которые реально встречаются в интерфейсе (DESIGN_SYSTEM §3.3: не ниже 4.5:1).
    @Test func usedTextAndBackgroundPairsMeetContrastInBothThemes() {
        typealias Palette = AppTheme.Palette
        let backgrounds = [Palette.canvas, Palette.surface, Palette.secondarySurface]
        var pairs: [(String, UIColor, UIColor)] = []
        let texts = [
            ("text", Palette.text), ("secondaryText", Palette.secondaryText), ("accent", Palette.accent)
        ]
        for (name, text) in texts {
            pairs += backgrounds.map { (name, text, $0) }
        }
        pairs += [
            ("tertiaryText/surface", Palette.tertiaryText, Palette.surface),
            ("tertiaryText/secondarySurface", Palette.tertiaryText, Palette.secondarySurface),
            ("danger/canvas", Palette.danger, Palette.canvas),
            ("danger/surface", Palette.danger, Palette.surface),
            ("danger/secondarySurface", Palette.danger, Palette.secondarySurface),
            ("danger/dangerBackground", Palette.danger, Palette.dangerBackground),
            ("info/infoBackground", Palette.info, Palette.infoBackground),
            ("info/secondarySurface", Palette.info, Palette.secondarySurface),
            ("success/successBackground", Palette.success, Palette.successBackground),
            ("success/secondarySurface", Palette.success, Palette.secondarySurface),
            ("warning/warningBackground", Palette.warning, Palette.warningBackground),
            ("warning/secondarySurface", Palette.warning, Palette.secondarySurface)
        ]
        for style in Self.themes {
            for (name, text, background) in pairs {
                let ratio = Self.contrast(Self.rgb(text, style), Self.rgb(background, style))
                #expect(ratio >= 4.5, "\(name) in \(style == .dark ? "dark" : "light"): \(ratio)")
            }
            // Номер шага кейса: реальные цвет цифры и подложка бейджа поверх secondarySurface.
            let badge = Self.stepBadgeColors(style)
            #expect(Self.contrast(badge.text, badge.background) >= 4.5)
        }
    }

    @Test func everyAppSymbolExistsInSystemCatalog() {
        for symbol in AppSymbol.allCases {
            #expect(UIImage(systemName: symbol.rawValue) != nil, "\(symbol.rawValue)")
        }
    }

    private static func rgb(_ color: UIColor, _ style: UIUserInterfaceStyle) -> [Double] {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        let resolved = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        #expect(resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        return [Double(red), Double(green), Double(blue)]
    }

    /// Цвет цифры и подложки номера шага из настоящего `TestCaseStepView` (подложка с её прозрачностью
    /// наложена на `secondarySurface`): тест следует за реальными значениями, а не за копиями констант.
    private static func stepBadgeColors(
        _ style: UIUserInterfaceStyle
    ) -> (text: [Double], background: [Double]) {
        let step = StepsInTestCase(
            hash: "step",
            position: 1,
            sharedStepHash: nil,
            sharedStepNestedHash: nil,
            attachments: [],
            action: "Action",
            expectedResult: "Result",
            data: nil,
            steps: []
        )
        let card = TestCaseStepView(step: step, number: "1")
        func descendants(_ view: UIView) -> [UIView] { [view] + view.subviews.flatMap(descendants) }
        let label = descendants(card).compactMap { $0 as? UILabel }.first { $0.text == "1" }
        let fill = label?.superview?.backgroundColor ?? .clear
        #expect(fill != .clear, "Step number badge has no background")
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        let resolved = fill.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        #expect(resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        let surface = rgb(AppTheme.Palette.secondarySurface, style)
        let background = zip([Double(red), Double(green), Double(blue)], surface)
            .map { badge, surface in badge * Double(alpha) + surface * (1 - Double(alpha)) }
        return (rgb(label?.textColor ?? .clear, style), background)
    }

    private static func luminance(_ rgb: [Double]) -> Double {
        let linear = rgb.map { $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
        return linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722
    }

    private static func contrast(_ first: [Double], _ second: [Double]) -> Double {
        let values = [luminance(first), luminance(second)]
        let (lighter, darker) = (values.max() ?? 0, values.min() ?? 0)
        return (lighter + 0.05) / (darker + 0.05)
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
