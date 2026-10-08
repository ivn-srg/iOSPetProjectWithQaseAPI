import Foundation

/// Read models preserve unknown counts rather than making missing API values look like zero.
struct ProjectMetrics: Codable, Equatable {
    var cases: Int? = nil
    var suites: Int? = nil
    var runs: Int? = nil
    var defects: Int? = nil
}

struct ProjectSummary: Codable, Equatable, Identifiable {
    let title: String
    let code: String
    let metrics: ProjectMetrics
    let description: String?
    let descriptionWasProvided: Bool
    var id: String { code }

    init(title: String, code: String, metrics: ProjectMetrics = ProjectMetrics(), description: String? = nil, descriptionWasProvided: Bool? = nil) {
        self.title = title
        self.code = code
        self.metrics = metrics
        self.description = description
        self.descriptionWasProvided = descriptionWasProvided ?? (description != nil)
    }

    private enum CodingKeys: String, CodingKey { case title, code, counts, metrics, description }
    private struct Counts: Decodable {
        let cases: Int?
        let suites: Int?
        let runs: Total?
        let defects: Total?
        struct Total: Decodable { let total: Int? }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        code = try container.decode(String.self, forKey: .code)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        descriptionWasProvided = container.contains(.description)
        if let cached = try container.decodeIfPresent(ProjectMetrics.self, forKey: .metrics) {
            metrics = cached
        } else {
            let counts = try container.decodeIfPresent(Counts.self, forKey: .counts)
            metrics = ProjectMetrics(cases: counts?.cases, suites: counts?.suites, runs: counts?.runs?.total, defects: counts?.defects?.total)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(code, forKey: .code)
        try container.encode(metrics, forKey: .metrics)
        if descriptionWasProvided { try container.encode(description, forKey: .description) }
    }
    func mergingDescription(from cached: ProjectSummary?) -> ProjectSummary {
        guard !descriptionWasProvided, let cached else { return self }
        return ProjectSummary(title: title, code: code, metrics: metrics, description: cached.description,
                              descriptionWasProvided: cached.descriptionWasProvided)
    }
    var menuSubtitle: String {
        let value = description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? code : code + " · " + value
    }

}

struct RunProgress: Codable, Equatable {
    let total: Int
    let completed: Int
    let percent: Int
}

struct RunStats: Codable, Equatable {
    let total: Int?
    let statuses: [String: Int]?
    let untested: Int?
    let inProgress: Int?
    let retest: Int?

    private enum CodingKeys: String, CodingKey {
        case total, statuses, untested, retest
        case inProgress = "in_progress"
    }

    var progress: RunProgress? {
        guard let total, total >= 0 else { return nil }
        guard total > 0 else { return RunProgress(total: 0, completed: 0, percent: 0) }
        let pending: [Int]
        if let statuses {
            pending = [statuses["untested"] ?? 0, statuses["in_progress"] ?? 0, statuses["retest"] ?? 0]
        } else {
            guard let untested, let inProgress, let retest else { return nil }
            pending = [untested, inProgress, retest]
        }
        // Saturating each subtraction avoids overflow from malformed API counters.
        let completed = pending.reduce(total) { remainder, value in
            remainder - min(remainder, max(0, value))
        }
        let percent = Int((Double(completed) / Double(total) * 100).rounded())
        return RunProgress(total: total, completed: completed, percent: percent)
    }
}

struct RunReadDTO: Codable, Equatable, Identifiable {
    let id: Int
    let title: String
    let status: Int?
    let statusText: String?
    let startTime: Date?
    let stats: RunStats?
    let cases: [Int]?

    init(id: Int, title: String, status: Int? = nil, statusText: String? = nil, startTime: Date? = nil, stats: RunStats? = nil, cases: [Int]? = nil) {
        self.id = id
        self.title = title
        self.status = status
        self.statusText = statusText
        self.startTime = startTime
        self.stats = stats
        self.cases = cases
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, status, stats, cases
        case statusText = "status_text"
        case startTime = "start_time"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        status = try container.decodeIfPresent(Int.self, forKey: .status)
        statusText = try container.decodeIfPresent(String.self, forKey: .statusText)
        stats = try container.decodeIfPresent(RunStats.self, forKey: .stats)
        cases = try container.decodeIfPresent([Int].self, forKey: .cases)
        if let value = try container.decodeIfPresent(String.self, forKey: .startTime) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            startTime = formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
        } else {
            startTime = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(statusText, forKey: .statusText)
        try container.encodeIfPresent(stats, forKey: .stats)
        try container.encodeIfPresent(cases, forKey: .cases)
        if let startTime {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            try container.encode(formatter.string(from: startTime), forKey: .startTime)
        }
    }

    var summary: ActiveRunSummary {
        ActiveRunSummary(id: id, title: title, startTime: startTime, progress: stats?.progress, statusText: statusText)
    }
}

struct ActiveRunSummary: Codable, Equatable, Identifiable {
    let id: Int
    let title: String
    let startTime: Date?
    let progress: RunProgress?
    let statusText: String?
}

struct DefectReadDTO: Codable, Equatable, Identifiable {
    let id: Int
    let title: String
    let severity: String?
    let status: String?
    let actualResult: String?

    private enum CodingKeys: String, CodingKey {
        case id, title, severity, status
        case actualResult = "actual_result"
    }
}

struct CaseSummary: Codable, Equatable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let priority: Int?
    let automation: Int?
    var suiteID: Int? = nil

    private enum CodingKeys: String, CodingKey {
        case id, title, description, priority, automation
        case suiteID = "suite_id"
    }
}

struct TestCaseReference: Codable, Hashable {
    let projectCode: String
    let caseID: Int
    var cacheKey: String { "\(projectCode):case:\(caseID)" }
}

struct RecentCaseItem: Codable, Equatable, Identifiable {
    let reference: TestCaseReference
    let title: String
    let description: String?
    let priority: Int?
    let automation: Int?
    let viewedAt: Date
    var id: String { reference.cacheKey }
}

struct HomeSnapshot: Codable, Equatable {
    let projectCode: String
    let activeRun: ActiveRunSummary?
    let metricsUpdatedAt: Date?
    let runUpdatedAt: Date?
}


extension CaseSummary {
    init(entity: TestListEntity) {
        self.init(id: entity.id, title: entity.title, description: entity.itemDescription,
                  priority: entity.priority?.menuItem.id, automation: entity.automation?.menuItem.id, suiteID: entity.parentId)
    }
}
