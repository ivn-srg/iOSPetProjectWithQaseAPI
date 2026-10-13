//
//  NetworkService.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 13.01.2024.
//

import Foundation

struct API {
    static let BASE_URL = "https://api.qase.io/v1"

    enum NetError: Error {
        case invalidURL, parsingError(String), serializationError(String),
             noInternetConnection, timeout, otherNetworkError(String), invalidCredantials,
             invalidRequest(String),
             httpError(statusCode: Int, message: String, retryAfter: TimeInterval?)
    }

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    enum Endpoint: String, CaseIterable {
        case attachment
        case author
        case configuration
        case project = "project"
        case customField = "custom_field"
        case defect
        case environment
        case milestone
        case plan
        case result
        case review
        case run
        case search
        case sharedParameter = "shared_parameter"
        case sharedStep = "shared_step"
        case suites = "suite"
        case cases = "case"
        case systemField = "system_field"
        case user

    }

    enum Operation: String, CaseIterable {
        case getAttachments = "GET /attachment"
        case getAttachment = "GET /attachment/{hash}"
        case deleteAttachment = "DELETE /attachment/{hash}"
        case uploadAttachment = "POST /attachment/{code}"
        case getAuthors = "GET /author"
        case getAuthor = "GET /author/{id}"
        case getCases = "GET /case/{code}"
        case createCase = "POST /case/{code}"
        case getCase = "GET /case/{code}/{id}"
        case updateCase = "PATCH /case/{code}/{id}"
        case deleteCase = "DELETE /case/{code}/{id}"
        case bulkCreateCases = "POST /case/{code}/bulk"
        case attachExternalIssueToCase = "POST /case/{code}/external-issue/attach"
        case detachExternalIssueFromCase = "POST /case/{code}/external-issue/detach"
        case getConfigurations = "GET /configuration/{code}"
        case createConfiguration = "POST /configuration/{code}"
        case createConfigurationGroup = "POST /configuration/{code}/group"
        case getCustomFields = "GET /custom_field"
        case createCustomField = "POST /custom_field"
        case getCustomField = "GET /custom_field/{id}"
        case updateCustomField = "PATCH /custom_field/{id}"
        case deleteCustomField = "DELETE /custom_field/{id}"
        case getSystemFields = "GET /system_field"
        case getDefects = "GET /defect/{code}"
        case createDefect = "POST /defect/{code}"
        case getDefect = "GET /defect/{code}/{id}"
        case updateDefect = "PATCH /defect/{code}/{id}"
        case deleteDefect = "DELETE /defect/{code}/{id}"
        case resolveDefect = "PATCH /defect/{code}/resolve/{id}"
        case updateDefectStatus = "PATCH /defect/{code}/status/{id}"
        case getEnvironments = "GET /environment/{code}"
        case createEnvironment = "POST /environment/{code}"
        case getEnvironment = "GET /environment/{code}/{id}"
        case updateEnvironment = "PATCH /environment/{code}/{id}"
        case deleteEnvironment = "DELETE /environment/{code}/{id}"
        case getMilestones = "GET /milestone/{code}"
        case createMilestone = "POST /milestone/{code}"
        case getMilestone = "GET /milestone/{code}/{id}"
        case updateMilestone = "PATCH /milestone/{code}/{id}"
        case deleteMilestone = "DELETE /milestone/{code}/{id}"
        case getPlans = "GET /plan/{code}"
        case createPlan = "POST /plan/{code}"
        case getPlan = "GET /plan/{code}/{id}"
        case updatePlan = "PATCH /plan/{code}/{id}"
        case deletePlan = "DELETE /plan/{code}/{id}"
        case getProjects = "GET /project"
        case createProject = "POST /project"
        case getProject = "GET /project/{code}"
        case deleteProject = "DELETE /project/{code}"
        case grantProjectAccess = "POST /project/{code}/access"
        case revokeProjectAccess = "DELETE /project/{code}/access"
        case getResults = "GET /result/{code}"
        case createResult = "POST /result/{code}/{id}"
        case createResultsBulk = "POST /result/{code}/{id}/bulk"
        case getResult = "GET /result/{code}/{hash}"
        case updateResult = "PATCH /result/{code}/{id}/{hash}"
        case deleteResult = "DELETE /result/{code}/{id}/{hash}"
        case getReviews = "GET /review/{code}"
        case createReview = "POST /review/{code}"
        case getReview = "GET /review/{code}/{id}"
        case updateReview = "PATCH /review/{code}/{id}"
        case deleteReview = "DELETE /review/{code}/{id}"
        case bulkCreateReviews = "POST /review/{code}/bulk"
        case getRuns = "GET /run/{code}"
        case createRun = "POST /run/{code}"
        case getRun = "GET /run/{code}/{id}"
        case updateRun = "PATCH /run/{code}/{id}"
        case deleteRun = "DELETE /run/{code}/{id}"
        case completeRun = "POST /run/{code}/{id}/complete"
        case updateRunPublicity = "PATCH /run/{code}/{id}/public"
        case attachExternalIssueToRun = "POST /run/{code}/external-issue"
        case search = "GET /search"
        case getSharedParameters = "GET /shared_parameter"
        case createSharedParameter = "POST /shared_parameter"
        case getSharedParameter = "GET /shared_parameter/{id}"
        case updateSharedParameter = "PATCH /shared_parameter/{id}"
        case deleteSharedParameter = "DELETE /shared_parameter/{id}"
        case getSharedSteps = "GET /shared_step/{code}"
        case createSharedStep = "POST /shared_step/{code}"
        case getSharedStep = "GET /shared_step/{code}/{hash}"
        case updateSharedStep = "PATCH /shared_step/{code}/{hash}"
        case deleteSharedStep = "DELETE /shared_step/{code}/{hash}"
        case getSuites = "GET /suite/{code}"
        case createSuite = "POST /suite/{code}"
        case getSuite = "GET /suite/{code}/{id}"
        case updateSuite = "PATCH /suite/{code}/{id}"
        case deleteSuite = "DELETE /suite/{code}/{id}"
        case getUsers = "GET /user"
        case getUser = "GET /user/{id}"

        var httpMethod: HTTPMethod {
            HTTPMethod(rawValue: String(rawValue.prefix { $0 != " " })) ?? .get
        }

        var pathTemplate: String {
            String(rawValue.drop { $0 != " " }.dropFirst())
        }

        var usesMultipartFormData: Bool {
            self == .uploadAttachment
        }
    }

    enum QueryParams: String {
        case limit = "limit"
        case offset = "offset"
        case search = "search"
        case suiteId = "suite_id"
        case milestoneId = "milestone_id"
        case severity, priority, type, behavior, automation, status
        case include, parentId = "parent_id"
        case externalIssueType = "external_issues[type]"
        case externalIssueIDs = "external_issues[ids][]"
        case environment, milestone, run, caseId = "case_id", member, api
        case fromEndTime = "from_end_time"
        case toEndTime = "to_end_time"
        case fromStartTime = "from_start_time"
        case toStartTime = "to_start_time"
        case query

        func item(_ value: String?) -> URLQueryItem {
            URLQueryItem(name: rawValue, value: value)
        }
    }

    struct UploadFile {
        let data: Data
        let fileName: String
        let mimeType: String

        init(data: Data, fileName: String, mimeType: String = "application/octet-stream") {
            self.data = data
            self.fileName = fileName
            self.mimeType = mimeType
        }
    }

    static let maxAttachmentCount = 20
    static let maxAttachmentSize = 32 * 1024 * 1024
    static let maxAttachmentRequestSize = 128 * 1024 * 1024

    static func makeURL(
        for operation: Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem]
    ) -> URL? {
        var url = URL(string: BASE_URL)

        // TODO: - шляпа надо переделать на норм компоновку url
        for pathComponent in operation.pathTemplate.split(separator: "/") {
            let component = String(pathComponent)
            if component.first == "{", component.last == "}" {
                let name = String(component.dropFirst().dropLast())
                guard let value = pathParameters[name], !value.isEmpty else { return nil }
                url = url?.appendingPathComponent(value)
            } else {
                url = url?.appendingPathComponent(component)
            }
        }

        guard let url else { return nil }
        guard !queryItems.isEmpty else { return url }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        return components?.url
    }

    static func httpError(from response: HTTPURLResponse, data: Data) -> NetError? {
        guard !(200 ... 299).contains(response.statusCode) else { return nil }

        let errorModel = try? JSONDecoder().decode(ResponseWithErrorModel.self, from: data)
        let message = errorModel?.errorMessage ?? errorModel?.message ?? "Qase API request failed."
        let retryAfter = response.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
        return .httpError(statusCode: response.statusCode, message: message, retryAfter: retryAfter)
    }

    static func decodeResponse<Response: Decodable>(
        from data: Data,
        as type: Response.Type
    ) throws(NetError) -> Response {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch let error as DecodingError {
            throw .parsingError(error.errorDescription ?? error.localizedDescription)
        } catch {
            throw .parsingError(error.localizedDescription)
        }
    }

    static func makeMultipartBody(files: [UploadFile], boundary: String) throws(NetError) -> Data {
        guard !files.isEmpty else {
            throw .invalidRequest("At least one attachment is required.")
        }
        guard files.count <= maxAttachmentCount else {
            throw .invalidRequest("Qase accepts up to 20 files per upload.")
        }

        var safeFiles = [(UploadFile, String)]()
        for file in files {
            guard file.data.count <= maxAttachmentSize else {
                throw .invalidRequest("Each attachment must be 32 MB or smaller.")
            }
            guard isValidMIMEType(file.mimeType) else {
                throw .invalidRequest("The attachment MIME type is invalid.")
            }
            safeFiles.append((file, safeDispositionValue(file.fileName)))
        }

        var bodySize = 0
        for (file, fileName) in safeFiles {
            let header = multipartHeader(boundary: boundary, fileName: fileName, mimeType: file.mimeType)
            bodySize += header.utf8.count + file.data.count + 2
            guard bodySize <= maxAttachmentRequestSize else {
                throw .invalidRequest("The total attachment upload must be 128 MB or smaller.")
            }
        }
        bodySize += boundary.utf8.count + 6
        guard bodySize <= maxAttachmentRequestSize else {
            throw .invalidRequest("The total attachment upload must be 128 MB or smaller.")
        }

        var body = Data()
        body.reserveCapacity(bodySize)
        for (file, fileName) in safeFiles {
            body
                .append(Data(multipartHeader(boundary: boundary, fileName: fileName, mimeType: file.mimeType)
                        .utf8))
            body.append(file.data)
            body.append(Data("\r\n".utf8))
        }
        body.append(Data("--\(boundary)--\r\n".utf8))
        return body
    }

    private static func multipartHeader(boundary: String, fileName: String, mimeType: String) -> String {
        "--\(boundary)\r\nContent-Disposition: form-data; name=\"file[]\"; filename=\"\(fileName)\"\r\nContent-Type: \(mimeType)\r\n\r\n"
    }

    private static func safeDispositionValue(_ value: String) -> String {
        let safeScalars = value.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }
        return String(String.UnicodeScalarView(safeScalars))
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private static func isValidMIMEType(_ value: String) -> Bool {
        let parts = value.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return false }
        let tokenCharacters =
            CharacterSet(
                charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!#$&^_.+-"
            )
        return parts.allSatisfy { !$0.isEmpty && $0.unicodeScalars.allSatisfy(tokenCharacters.contains) }
    }
}

protocol NetworkManager: AnyObject {
    func performRequest<T: Decodable>(
        with data: Encodable?,
        from urlString: URL?,
        method: API.HTTPMethod,
        modelType: T.Type
    ) async throws(API.NetError) -> T

    func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T

    func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem],
        with data: Encodable?,
        modelType: T.Type
    ) async throws(API.NetError) -> T

    func composeURL(
        for method: API.Endpoint,
        urlComponents: [String?]?,
        queryItems: [API.QueryParams: Int?]?
    ) -> URL?

    func composeURL(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem]
    ) -> URL?

    func auth(by token: String) async throws -> Bool
}

final class APIManager: NetworkManager {
    private let tokenProvider: () -> String?
    private let transport: HTTPTransport

    init(tokenProvider: @escaping () -> String?, transport: HTTPTransport) {
        self.tokenProvider = tokenProvider
        self.transport = transport
    }

    func auth(by token: String) async throws -> Bool {
        guard
            !token.isEmpty,
            let url = composeURL(for: .project, urlComponents: nil)
        else {
            return false
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(token, forHTTPHeaderField: "Token")

        let (data, response) = try await transport.send(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 { return false }
        if let error = API.httpError(from: httpResponse, data: data) { throw error }

        return true
    }

    func performRequest<T: Decodable>(
        with data: Encodable? = nil,
        from urlString: URL?,
        method: API.HTTPMethod,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        guard
            let url = urlString,
            let authToken = tokenProvider()
        else { throw .invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue(authToken, forHTTPHeaderField: "Token")

        if let data = data {
            let encoder = JSONEncoder()
            let jsonData: Data
            encoder.keyEncodingStrategy = .convertToSnakeCase
            do {
                jsonData = try encoder.encode(data)
                request.httpBody = jsonData
                request.addValue("application/json", forHTTPHeaderField: "content-type")
            } catch {
                throw .serializationError(error.localizedDescription)
            }
        }

        if method == .delete || method == .get {
            request.addValue("application/json", forHTTPHeaderField: "accept")
        }

        return try await makeHTTPRequest(for: request, codableModelType: modelType)
    }

    func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        with data: Encodable? = nil,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        guard let url = composeURL(for: operation, pathParameters: pathParameters, queryItems: queryItems)
        else {
            throw .invalidURL
        }

        return try await performRequest(
            with: data,
            from: url,
            method: operation.httpMethod,
            modelType: modelType
        )
    }

    func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        guard operation.usesMultipartFormData,
              let url = composeURL(for: operation, pathParameters: pathParameters, queryItems: []),
              let authToken = tokenProvider() else {
            throw .invalidURL
        }

        let boundary = "QaseBoundary-\(UUID().uuidString)"
        let body = try API.makeMultipartBody(files: files, boundary: boundary)

        var request = URLRequest(url: url)
        request.httpMethod = operation.httpMethod.rawValue
        request.httpBody = body
        request.addValue(authToken, forHTTPHeaderField: "Token")
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        return try await makeHTTPRequest(for: request, codableModelType: modelType)
    }

    private func makeHTTPRequest<T: Decodable>(
        for request: URLRequest,
        codableModelType: T.Type
    ) async throws(API.NetError) -> T {
        do {
            let (data, response) = try await transport.send(request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw API.NetError.otherNetworkError(URLError(.badServerResponse).localizedDescription)
            }

            if let apiError = API.httpError(from: httpResponse, data: data) { throw apiError }

            return try API.decodeResponse(from: data, as: codableModelType)
        } catch let error as API.NetError {
            throw error
        } catch let error as DecodingError {
            throw .parsingError(error.errorDescription ?? error.localizedDescription)
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw .noInternetConnection
        } catch let error as URLError where error.code == .timedOut {
            throw .timeout
        } catch {
            throw .otherNetworkError(error.localizedDescription)
        }
    }

    func composeURL(
        for method: API.Endpoint,
        urlComponents: [String?]?,
        queryItems: [API.QueryParams: Int?]? = nil
    ) -> URL? {
        API.makeLegacyURL(for: method, urlComponents: urlComponents, queryItems: queryItems)
    }

    func composeURL(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem]
    ) -> URL? {
        API.makeURL(for: operation, pathParameters: pathParameters, queryItems: queryItems)
    }
}

final class APIMockManager: NetworkManager {
    private let bundle: Bundle
    private let lock = NSLock()
    private var records: [String: [[String: Any]]] = [:]

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func auth(by token: String) async throws -> Bool { true }

    func performRequest<T: Decodable>(
        with data: Encodable? = nil,
        from urlString: URL?,
        method: API.HTTPMethod,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        guard let url = urlString else { throw .invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        if let data {
            do {
                let encoder = JSONEncoder()
                encoder.keyEncodingStrategy = .convertToSnakeCase
                request.httpBody = try encoder.encode(data)
            } catch {
                throw .serializationError(error.localizedDescription)
            }
        }
        return try await makeHTTPRequest(for: request, codableModelType: modelType)
    }

    func performRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        with data: Encodable? = nil,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        guard let url = composeURL(for: operation, pathParameters: pathParameters, queryItems: queryItems)
        else {
            throw .invalidURL
        }
        return try await performRequest(
            with: data,
            from: url,
            method: operation.httpMethod,
            modelType: modelType
        )
    }

    func performMultipartRequest<T: Decodable>(
        for operation: API.Operation,
        pathParameters: [String: String],
        files: [API.UploadFile],
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        guard composeURL(for: operation, pathParameters: pathParameters, queryItems: []) != nil else {
            throw .invalidURL
        }
        throw .invalidRequest("The demo does not support attachment uploads.")
    }

    private func makeHTTPRequest<T: Decodable>(
        for request: URLRequest,
        codableModelType: T.Type
    ) async throws(API.NetError) -> T {
        do {
            let result = try routedResponse(for: request)
            let data = try JSONSerialization.data(withJSONObject: ["status": true, "result": result])
            return try API.decodeResponse(from: data, as: codableModelType)
        } catch let error as API.NetError {
            throw error
        } catch {
            throw .otherNetworkError(error.localizedDescription)
        }
    }

    /// Route by the complete method/path, so a detail cannot accidentally decode a list.
    private func routedResponse(for request: URLRequest) throws -> Any {
        lock.lock()
        defer { lock.unlock() }
        guard let url = request.url, url.host == "api.qase.io" else { throw API.NetError.invalidURL }
        let path = url.path.split(separator: "/").map(String.init)
        guard path.first == "v1", (2 ... 4).contains(path.count) else { throw API.NetError.invalidURL }
        let endpoint = path[1]
        guard ["project", "suite", "case", "run", "defect"].contains(endpoint) else {
            throw API.NetError.invalidRequest("Unsupported demo endpoint.")
        }
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? { query.first { $0.name == name }?.value }
        let method = request.httpMethod ?? "GET"
        let projectCode = endpoint == "project" ? nil : path.count >= 3 ? path[2] : nil
        if endpoint != "project" {
            guard let projectCode,
                  ["DEMO", "1F"].contains(projectCode) || (records["project"] ?? [])
                  .contains(where: { $0["code"] as? String == projectCode }) else {
                throw API.NetError.httpError(statusCode: 404, message: "Project not found.", retryAfter: nil)
            }
        }
        let key = endpoint == "project" ? "project" : "\(endpoint)/\(projectCode ?? "")"
        if records[key] == nil { records[key] = try initialRecords(
            endpoint: endpoint,
            projectCode: projectCode
        ) }
        var entities = records[key] ?? []
        let detailID = endpoint == "project" ? (path.count == 3 ? path[2] : nil) :
            (path.count == 4 ? path[3] : nil)
        if endpoint == "project", path.count > 3 { throw API.NetError.invalidURL }
        func matchesID(_ entity: [String: Any]) -> Bool {
            if endpoint == "project" { return entity["code"] as? String == detailID }
            return (entity["id"] as? Int).map(String.init) == detailID
        }
        switch method {
        case "GET":
            if detailID != nil {
                guard var entity = entities.first(where: matchesID) else {
                    throw API.NetError.httpError(
                        statusCode: 404,
                        message: "Entity not found.",
                        retryAfter: nil
                    )
                }
                if endpoint == "run", value("include") != "cases" { entity.removeValue(forKey: "cases") }
                return entity
            }
            let total = entities.count
            if let search = value("search"), !search.isEmpty {
                entities = entities
                    .filter { ($0["title"] as? String ?? "").localizedCaseInsensitiveContains(search) }
            }
            if endpoint == "run", let status = value("status") {
                entities = entities.filter { $0["status_text"] as? String == status }
            }
            if endpoint == "case", let suite = value("suite_id"), let suiteID = Int(suite) {
                entities = entities.filter { $0["suite_id"] as? Int == suiteID }
            }
            if endpoint == "suite", let parent = value("parent_id"), let parentID = Int(parent) {
                entities = entities.filter { ($0["parent_id"] as? Int ?? 0) == parentID }
            }
            let filtered = entities.count
            let offset = max(0, Int(value("offset") ?? "0") ?? 0)
            let limit = max(
                0,
                min(
                    PaginationPolicy.mockMaximumPageSize,
                    Int(value("limit") ?? "") ?? PaginationPolicy.pageSize
                )
            )
            let page = Array(entities.dropFirst(offset).prefix(limit))
            return ["total": total, "filtered": filtered, "count": page.count,
                    "entities": page] as [String: Any]
        case "POST" where detailID == nil:
            var entity = try body(of: request)
            if endpoint == "project" {
                guard let code = entity["code"] as? String,
                      !code.isEmpty else { throw API.NetError.invalidRequest("Project code is required.") }
                entity["counts"] = [
                    "cases": 0,
                    "suites": 0,
                    "milestones": 0,
                    "runs": ["total": 0, "active": 0],
                    "defects": ["total": 0, "open": 0]
                ] as [String: Any]
                entities.append(entity)
                records[key] = entities
                return ["code": code]
            }
            let id = (entities.compactMap { $0["id"] as? Int }.max() ?? 0) + 1
            if endpoint == "case", var template = try fixture("test_cases_data").first {
                entity["suite_id"] = entity["suite_id"] ?? NSNull()
                template.merge(entity) { _, new in new }
                entity = template
            }
            entity["id"] = id
            entity["position"] = entities.count + 1
            entities.append(entity)
            records[key] = entities
            return ["id": id]
        case "PATCH" where detailID != nil:
            guard let index = entities.firstIndex(where: matchesID)
            else { throw API.NetError.invalidRequest("Entity not found.") }
            entities[index].merge(try body(of: request)) { _, new in new }
            records[key] = entities
            return ["id": entities[index]["id"] ?? 0]
        case "DELETE" where detailID != nil:
            guard entities.contains(where: matchesID)
            else { throw API.NetError.invalidRequest("Entity not found.") }
            entities.removeAll(where: matchesID)
            records[key] = entities
            return [:] as [String: Any]
        default:
            throw API.NetError.invalidRequest("Unsupported demo operation.")
        }
    }

    private func body(of request: URLRequest) throws -> [String: Any] {
        guard let data = request.httpBody else { return [:] }
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }

    private func fixture(_ name: String) throws -> [[String: Any]] {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw API.NetError.invalidRequest("Missing demo fixture: \(name)")
        }
        let root = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        return (root?["result"] as? [String: Any])?["entities"] as? [[String: Any]] ?? []
    }

    private func initialRecords(endpoint: String, projectCode: String?) throws -> [[String: Any]] {
        switch endpoint {
        case "project":
            return try fixture("project_data")
        case "case":
            let cases = try fixture("test_cases_data")
            guard projectCode == "DEMO" else { return projectCode == "1F" ? cases : [] }
            return cases.map { source in
                var entity = source
                entity["title"] = "Demo · \(source["title"] as? String ?? "")"
                entity["suite_id"] = source["suite_id"] ?? NSNull()
                return entity
            }
        case "suite":
            let suites = try fixture("suites_data")
            return ["DEMO", "1F"].contains(projectCode ?? "") ? suites : []
        case "run", "defect":
            return try fixture(endpoint == "run" ? "runs_data" : "defects_data")
                .filter { $0["project_code"] as? String == projectCode }
        default:
            return []
        }
    }

    func composeURL(
        for method: API.Endpoint,
        urlComponents: [String?]?,
        queryItems: [API.QueryParams: Int?]? = nil
    ) -> URL? {
        API.makeLegacyURL(for: method, urlComponents: urlComponents, queryItems: queryItems)
    }

    func composeURL(
        for operation: API.Operation,
        pathParameters: [String: String],
        queryItems: [URLQueryItem]
    ) -> URL? {
        API.makeURL(for: operation, pathParameters: pathParameters, queryItems: queryItems)
    }
}

extension API {
    static func makeLegacyURL(
        for endpoint: Endpoint,
        urlComponents: [String?]?,
        queryItems: [QueryParams: Int?]?
    ) -> URL? {
        guard var url = URL(string: "\(BASE_URL)/\(endpoint.rawValue)") else { return nil }
        for component in urlComponents ?? [] {
            if let component { url.appendPathComponent(component) }
        }
        let items = (queryItems ?? [:]).compactMap { parameter, value in
            value.map { URLQueryItem(name: parameter.rawValue, value: String($0)) }
        }
        if !items.isEmpty { url.append(queryItems: items) }
        return url
    }
}
