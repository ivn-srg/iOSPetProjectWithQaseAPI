//
//  TestCaseFieldEnums.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 23.04.2025.
//

enum Severity: String, CaseIterable, MenuDataSource, Codable {
    case nothing = "Not set"
    case blocker = "Blocker"
    case critical = "Critical"
    case major = "Major"
    case normal = "Normal"
    case minor = "Minor"
    case trivial = "Trivial"

    var localized: String {
        self.rawValue.localized
    }

    var apiValue: Int {
        switch self {
        case .nothing: 0
        case .blocker: 1
        case .critical: 2
        case .major: 3
        case .normal: 4
        case .minor: 5
        case .trivial: 6
        }
    }

    @MainActor
    var menuItem: MenuItem { Self.dataSource.first { $0.id == apiValue }! }

    @MainActor
    static var dataSource: [MenuItem] {
        [
            MenuItem(
                id: Severity.nothing.apiValue,
                title: Severity.nothing.localized,
                image: AppImages.minus
            ),
            MenuItem(
                id: Severity.blocker.apiValue,
                title: Severity.blocker.localized,
                image: AppImages.nosign
            ),
            MenuItem(
                id: Severity.critical.apiValue,
                title: Severity.critical.localized,
                image: AppImages.chevronUp2
            ),
            MenuItem(
                id: Severity.major.apiValue,
                title: Severity.major.localized,
                image: AppImages.arrowUp
            ),
            MenuItem(
                id: Severity.normal.apiValue,
                title: Severity.normal.localized,
                image: AppImages.circle
            ),
            MenuItem(
                id: Severity.minor.apiValue,
                title: Severity.minor.localized,
                image: AppImages.arrowDown
            ),
            MenuItem(
                id: Severity.trivial.apiValue,
                title: Severity.trivial.localized,
                image: AppImages.chevronDown2
            ),
        ]
    }

    init(_ number: Int) {
        self = switch number {
        case 1: .blocker
        case 2: .critical
        case 3: .major
        case 4: .normal
        case 5: .minor
        case 6: .trivial
        default: .nothing
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(apiValue)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)

        self.init(rawValue)
    }
}

enum Status: String, CaseIterable, MenuDataSource, Codable {
    case actual = "Actual"
    case draft = "Draft"
    case deprecated = "Deprecated"

    var localized: String {
        self.rawValue.localized
    }

    var apiValue: Int {
        switch self {
        case .actual: 0
        case .draft: 1
        case .deprecated: 2
        }
    }

    @MainActor
    var menuItem: MenuItem { Self.dataSource.first { $0.id == apiValue }! }

    @MainActor
    static var dataSource: [MenuItem] {
        [
            MenuItem(id: Status.actual.apiValue, title: Status.actual.localized),
            MenuItem(id: Status.draft.apiValue, title: Status.draft.localized),
            MenuItem(id: Status.deprecated.apiValue, title: Status.deprecated.localized)
        ]
    }

    init(_ number: Int) {
        self = switch number {
        case 1: .draft
        case 2: .deprecated
        default: .actual
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(apiValue)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)

        self.init(rawValue)
    }
}

enum Priority: String, CaseIterable, MenuDataSource, Codable {
    case nothing = "Not set"
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    var localized: String {
        self.rawValue.localized
    }

    var apiValue: Int {
        switch self {
        case .nothing: 0
        case .high: 1
        case .medium: 2
        case .low: 3
        }
    }

    @MainActor
    var menuItem: MenuItem { Self.dataSource.first { $0.id == apiValue }! }

    @MainActor
    static var dataSource: [MenuItem] {
        [
            MenuItem(
                id: Priority.nothing.apiValue,
                title: Priority.nothing.localized,
                image: AppImages.minus
            ),
            MenuItem(
                id: Priority.high.apiValue,
                title: Priority.high.localized,
                image: AppImages.arrowUp
            ),
            MenuItem(
                id: Priority.medium.apiValue,
                title: Priority.medium.localized,
                image: AppImages.circle
            ),
            MenuItem(
                id: Priority.low.apiValue,
                title: Priority.low.localized,
                image: AppImages.arrowDown
            )
        ]
    }

    init(_ number: Int) {
        self = switch number {
        case 1: .high
        case 2: .medium
        case 3: .low
        default: .nothing
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(apiValue)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)

        self.init(rawValue)
    }
}

enum Behavior: String, CaseIterable, MenuDataSource, Codable {
    case nothing = "Not set"
    case positive = "Positive"
    case negative = "Negative"
    case destructive = "Destructive"

    var localized: String {
        self.rawValue.localized
    }

    var apiValue: Int {
        switch self {
        case .nothing: 1
        case .positive: 2
        case .negative: 3
        case .destructive: 4
        }
    }

    @MainActor
    var menuItem: MenuItem { Self.dataSource.first { $0.id == apiValue }! }

    @MainActor
    static var dataSource: [MenuItem] {
        [
            MenuItem(id: Behavior.nothing.apiValue, title: Behavior.nothing.localized),
            MenuItem(id: Behavior.positive.apiValue, title: Behavior.positive.localized),
            MenuItem(id: Behavior.negative.apiValue, title: Behavior.negative.localized),
            MenuItem(id: Behavior.destructive.apiValue, title: Behavior.destructive.localized)
        ]
    }

    init(_ number: Int) {
        self = switch number {
        case 2: .positive
        case 3: .negative
        case 4: .destructive
        default: .nothing
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(apiValue)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)

        self.init(rawValue)
    }
}

enum Types: String, CaseIterable, MenuDataSource, Codable {
    case other = "Other"
    case smoke = "Smoke"
    case regression = "Regression"
    case security = "Security"
    case usability = "Usability"
    case performance = "Performance"
    case acceptance = "Acceptance"
    case functional = "Functional"
    case compatibility = "Compatibility"
    case integration = "Integration"
    case exploratory = "Exploratory"

    var localized: String {
        self.rawValue.localized
    }

    var apiValue: Int {
        switch self {
        case .other: 1
        case .smoke: 2
        case .regression: 3
        case .security: 4
        case .usability: 5
        case .performance: 6
        case .acceptance: 7
        case .functional: 8
        case .compatibility: 9
        case .integration: 10
        case .exploratory: 11
        }
    }

    @MainActor
    var menuItem: MenuItem { Self.dataSource.first { $0.id == apiValue }! }

    @MainActor
    static var dataSource: [MenuItem] {
        [
            MenuItem(id: Types.other.apiValue, title: Types.other.localized),
            MenuItem(id: Types.smoke.apiValue, title: Types.smoke.localized),
            MenuItem(id: Types.regression.apiValue, title: Types.regression.localized),
            MenuItem(id: Types.security.apiValue, title: Types.security.localized),
            MenuItem(id: Types.usability.apiValue, title: Types.usability.localized),
            MenuItem(id: Types.performance.apiValue, title: Types.performance.localized),
            MenuItem(id: Types.acceptance.apiValue, title: Types.acceptance.localized),
            MenuItem(id: Types.functional.apiValue, title: Types.functional.localized),
            MenuItem(id: Types.compatibility.apiValue, title: Types.compatibility.localized),
            MenuItem(id: Types.integration.apiValue, title: Types.integration.localized),
            MenuItem(id: Types.exploratory.apiValue, title: Types.exploratory.localized),
        ]
    }

    init(_ number: Int) {
        self = switch number {
        case 2: .smoke
        case 3: .regression
        case 4: .security
        case 5: .usability
        case 6: .performance
        case 7: .acceptance
        case 8: .functional
        case 9: .compatibility
        case 10: .integration
        case 11: .exploratory
        default: .other
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(apiValue)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)

        self.init(rawValue)
    }
}

enum Layer: String, CaseIterable, MenuDataSource, Codable {
    case nothing = "Not set"
    case e2e = "E2E"
    case api = "API"
    case unit = "Unit"

    var localized: String {
        self.rawValue.localized
    }

    var apiValue: Int {
        switch self {
        case .nothing: 0
        case .e2e: 1
        case .api: 2
        case .unit: 3
        }
    }

    @MainActor
    var menuItem: MenuItem { Self.dataSource.first { $0.id == apiValue }! }

    @MainActor
    static var dataSource: [MenuItem] {
        [
            MenuItem(id: Layer.nothing.apiValue, title: Layer.nothing.localized, image: AppImages.minus),
            MenuItem(id: Layer.e2e.apiValue, title: Layer.e2e.localized, image: AppImages.desktopcomputer),
            MenuItem(
                id: Layer.api.apiValue,
                title: Layer.api.localized,
                image: AppImages.externaldriveConnectedToLineBelowFill
            ),
            MenuItem(
                id: Layer.unit.apiValue,
                title: Layer.unit.localized,
                image: AppImages.gearshape2Fill
            )
        ]
    }

    init(_ number: Int) {
        self = switch number {
        case 1: .e2e
        case 2: .api
        case 3: .unit
        default: .nothing
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(apiValue)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)

        self.init(rawValue)
    }
}

enum AutomationStatus: String, CaseIterable, MenuDataSource, Codable {
    case manual = "Manual"
    case toBeAutomated = "To be automated"
    case automation = "Automated"

    var localized: String {
        self.rawValue.localized
    }

    var apiValue: Int {
        switch self {
        case .manual: 0
        case .toBeAutomated: 1
        case .automation: 2
        }
    }

    @MainActor
    var menuItem: MenuItem { Self.dataSource.first { $0.id == apiValue }! }

    @MainActor
    static var dataSource: [MenuItem] {
        [
            MenuItem(
                id: AutomationStatus.manual.apiValue,
                title: AutomationStatus.manual.localized,
                image: AppImages.handRaised
            ),
            MenuItem(
                id: AutomationStatus.toBeAutomated.apiValue,
                title: AutomationStatus.toBeAutomated.localized,
                image: AppImages.person2BadgeGearshapeFill
            ),
            MenuItem(
                id: AutomationStatus.automation.apiValue,
                title: AutomationStatus.automation.localized,
                image: AppImages.gearshapeFill
            )
        ]
    }

    init(_ number: Int) {
        self = switch number {
        case 1: .toBeAutomated
        case 2: .automation
        default: .manual
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(apiValue)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)

        self.init(rawValue)
    }
}
