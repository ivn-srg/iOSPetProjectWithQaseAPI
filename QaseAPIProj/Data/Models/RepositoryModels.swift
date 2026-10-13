import Foundation

struct RepositoryLocation: Hashable {
    let projectCode: String
    let suiteID: Int?
}

struct RepositoryItemReference: Hashable {
    let projectCode: String
    let id: Int
    let isSuite: Bool
    var key: String { "\(projectCode):\(isSuite ? "suite" : "case"):\(id)" }
}

struct RepositoryLevelSnapshot: Codable {
    let caseIDs: [Int]
    let updatedAt: Date
}

struct RepositoryBreadcrumb: Identifiable, Equatable {
    let id: Int?
    let title: String
}
