import Foundation

enum AppTab: Int, CaseIterable {
    case home, repository, work, settings
}

struct PaginationPolicy {
    static let pageSize = 50
    static let mockMaximumPageSize = 100
    static let prefetchThreshold = 3

    static func hasMore(received: Int, offset: Int, total: Int?) -> Bool {
        received > 0 && (total.map { offset < $0 } ?? (received >= pageSize))
    }
}

struct SearchPolicy {
    static let debounce: Duration = .milliseconds(300)
}

struct CachePolicy {
    static let recentRetention = 20
    static let recentPreview = 3
    static let schemaVersion: UInt64 = 5
    static let firstOwnedSchema: UInt64 = 2
    static let standaloneStepsSchema: UInt64 = 4
}

extension AppTab {
    var accessibilityID: AccessibilityID {
        switch self {
        case .home: return .tabHome
        case .repository: return .tabRepository
        case .work: return .tabWork
        case .settings: return .tabSettings
        }
    }
}
