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
    
    var menuItem: MenuItem {
        let index = switch self {
        case .nothing: 0
        case .blocker: 1
        case .critical: 2
        case .major: 3
        case .normal: 4
        case .minor: 5
        case .trivial: 6
        }
        return Self.dataSource[index]
    }
    
    static var dataSource = [
        MenuItem(id: 0, title: Severity.nothing.localized, image: AppTheme.minusImage),
        MenuItem(id: 1, title: Severity.blocker.localized, image: AppTheme.nosignImage),
        MenuItem(id: 2, title: Severity.critical.localized, image: AppTheme.chevronDoubleUpImage),
        MenuItem(id: 3, title: Severity.major.localized, image: AppTheme.chevronUpImage),
        MenuItem(id: 4, title: Severity.normal.localized, image: AppTheme.circleImage),
        MenuItem(id: 5, title: Severity.minor.localized, image: AppTheme.chevronDownImage),
        MenuItem(id: 6, title: Severity.trivial.localized, image: AppTheme.chevronDoubleDownImage),
    ]
    
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
    
    var menuItem: MenuItem {
        let index = switch self {
        case .actual: 0
        case .draft: 1
        case .deprecated: 2
        }
        return Self.dataSource[index]
    }
    
    static var dataSource = [
        MenuItem(id: 0, title: Status.actual.localized),
        MenuItem(id: 1, title: Status.draft.localized),
        MenuItem(id: 2, title: Status.deprecated.localized)
    ]
    
    init(_ number: Int) {
        self = switch number {
        case 1: .draft
        case 2: .deprecated
        default: .actual
        }
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        
        self.init(rawValue)
    }
}

enum Priority: String, CaseIterable, MenuDataSource, Codable {
    case nothing = "Not Set"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var localized: String {
        self.rawValue.localized
    }
    
    var menuItem: MenuItem {
        let index = switch self {
        case .nothing: 0
        case .high: 1
        case .medium: 2
        case .low: 3
        }
        return Self.dataSource[index]
    }
    
    static var dataSource = [
        MenuItem(id: 0, title: Priority.nothing.localized, image: AppTheme.minusImage),
        MenuItem(id: 1, title: Priority.high.localized, image: AppTheme.arrowUpImage),
        MenuItem(id: 2, title: Priority.medium.localized, image: AppTheme.circleImage),
        MenuItem(id: 3, title: Priority.low.localized, image: AppTheme.arrowDownImage)
    ]
    
    init(_ number: Int) {
        self = switch number {
        case 1: .high
        case 2: .medium
        case 3: .low
        default: .nothing
        }
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        
        self.init(rawValue)
    }
}

enum Behavior: String, CaseIterable, MenuDataSource, Codable {
    case nothing = "Not Set"
    case positive = "Positive"
    case negative = "Negative"
    case destructive = "Destructive"
    
    var localized: String {
        self.rawValue.localized
    }
    
    var menuItem: MenuItem {
        let index = switch self {
        case .nothing: 0
        case .positive: 1
        case .negative: 2
        case .destructive: 3
        }
        return Self.dataSource[index]
    }
    
    static var dataSource = [
        MenuItem(id: 0, title: Behavior.nothing.localized),
        MenuItem(id: 1, title: Behavior.positive.localized),
        MenuItem(id: 2, title: Behavior.negative.localized),
        MenuItem(id: 3, title: Behavior.destructive.localized)
    ]
    
    init(_ number: Int) {
        self = switch number {
        case 1: .positive
        case 2: .negative
        case 3: .destructive
        default: .nothing
        }
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        
        self.init(rawValue)
    }
}

enum Types: String, CaseIterable, MenuDataSource, Codable {
    case other = "Other"
    case functional = "Functional"
    case smoke = "Smoke"
    case regression = "Regression"
    case security = "Security"
    case utility = "Utility"
    case perfomance = "Perfomance"
    case accertance = "Accertance"
    case compatibility = "Compatibility"
    case exploratory = "Exploratory"
    case integration = "Integration"
    
    var localized: String {
        self.rawValue.localized
    }
    
    var menuItem: MenuItem {
        let index = switch self {
        case .other: 0
        case .functional: 1
        case .smoke: 2
        case .regression: 3
        case .security: 4
        case .utility: 5
        case .perfomance: 6
        case .accertance: 7
        case .compatibility: 8
        case .exploratory: 9
        case .integration: 10
        }
        return Self.dataSource[index]
    }
    
    static var dataSource = [
        MenuItem(id: 0, title: Types.other.localized),
        MenuItem(id: 1, title: Types.functional.localized),
        MenuItem(id: 2, title: Types.smoke.localized),
        MenuItem(id: 3, title: Types.regression.localized),
        MenuItem(id: 4, title: Types.security.localized),
        MenuItem(id: 5, title: Types.utility.localized),
        MenuItem(id: 6, title: Types.perfomance.localized),
        MenuItem(id: 7, title: Types.accertance.localized),
        MenuItem(id: 7, title: Types.compatibility.localized),
        MenuItem(id: 8, title: Types.exploratory.localized),
        MenuItem(id: 9, title: Types.integration.localized),
    ]
    
    init(_ number: Int) {
        self = switch number {
        case 1: .functional
        case 2: .smoke
        case 3: .regression
        case 4: .security
        case 5: .utility
        case 6: .perfomance
        case 7: .accertance
        case 8: .compatibility
        case 9: .exploratory
        case 10: .integration
        default: .other
        }
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        
        self.init(rawValue)
    }
}

enum Layer: String, CaseIterable, MenuDataSource, Codable {
    case e2e = "E2E"
    case api = "API"
    case unit = "Unit"
    
    var localized: String {
        self.rawValue.localized
    }
    
    var menuItem: MenuItem {
        let index = switch self {
        case .e2e: 0
        case .api: 1
        case .unit: 2
        }
        return Self.dataSource[index]
    }
    
    static var dataSource = [
        MenuItem(id: 0, title: Layer.e2e.localized, image: AppTheme.computerImage),
        MenuItem(id: 1, title: Layer.api.localized, image: AppTheme.apiImage),
        MenuItem(id: 2, title: Layer.unit.localized, image: AppTheme.gearDoubleFillImage)
    ]
    
    init(_ number: Int) {
        self = switch number {
        case 1: .api
        case 2: .unit
        default: .e2e
        }
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
    
    var menuItem: MenuItem {
        let index = switch self {
        case .manual: 0
        case .toBeAutomated: 1
        case .automation: 2
        }
        return Self.dataSource[index]
    }
    
    static var dataSource = [
        MenuItem(id: 0, title: AutomationStatus.manual.localized, image: AppTheme.handRaisedImage),
        MenuItem(id: 1, title: AutomationStatus.toBeAutomated.localized, image: AppTheme.personWithGearshapeImage),
        MenuItem(id: 2, title: AutomationStatus.automation.localized, image: AppTheme.gearshapeImage)
    ]
    
    init(_ number: Int) {
        self = switch number {
        case 1: .toBeAutomated
        case 2: .automation
        default: .manual
        }
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        
        self.init(rawValue)
    }
}
