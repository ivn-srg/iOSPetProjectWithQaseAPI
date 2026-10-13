//
//  QaseAPIProjTests.swift
//  QaseAPIProjTests
//
//  Created by Sergey Ivanov on 01.04.2025.
//

@testable import QaseAPIProj
import Testing
import UIKit

struct QaseAPIProjTests {

    let apiManager = APIMockManager.shared

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        let whiteColor = UIColor.white
        let blackColor = UIColor.black

        #expect(whiteColor.toHex() == "#FFFFFF")
        #expect(blackColor.toHex() == "#000000")

        #expect(UIColor(hex: "#0000FF") == .blue)
        #expect(UIColor(hex: "#996633") == .brown)
    }

    @Test("API compose method checking")
    func checkValidURL() async throws {
        let projectUrl = apiManager.composeURL(for: .project, urlComponents: nil, queryItems: [.limit: 10])!

        #expect(projectUrl.absoluteString == "https://api.qase.io/v1/project?limit=10")
    }

    @Test("Qase operations preserve repeated query parameters and path values")
    func checkOperationURL() async throws {
        let url = apiManager.composeURL(
            for: .getCases,
            pathParameters: ["code": "DEMO"],
            queryItems: [
                URLQueryItem(name: "search", value: "login flow"),
                URLQueryItem(name: "external_issues[ids][]", value: "ISSUE-1"),
                URLQueryItem(name: "external_issues[ids][]", value: "ISSUE-2")
            ]
        )!

        #expect(url.path == "/v1/case/DEMO")
        #expect(url.query?.contains("search=login%20flow") == true)
        #expect(url.query?.components(separatedBy: "external_issues%5Bids%5D%5B%5D=").count == 3)
    }

    @Test("Qase API operations expose their documented HTTP method")
    func checkOperationMethod() async throws {
        #expect(API.Operation.getCases.httpMethod == .get)
        #expect(API.Operation.createCase.httpMethod == .post)
        #expect(API.Operation.updateCase.httpMethod == .patch)
        #expect(API.Operation.deleteCase.httpMethod == .delete)
        #expect(API.Operation.allCases.count == 89)
    }

    @Test("Qase resource DTO preserves fields outside its common properties")
    func checkResourceDTOPreservesAdditionalFields() async throws {
        let data = Data("""
        {"id":7,"title":"Run","status":"in_progress","custom_value":{"enabled":true}}
        """.utf8)
        let dto = try JSONDecoder().decode(QaseAPIResourceDTO.self, from: data)
        #expect(dto.id == .integer(7))
        #expect(dto.fields?["custom_value"] == .object(["enabled": .bool(true)]))
    }

    @Test("Qase resource DTO accepts UUID identifiers")
    func checkResourceDTOAcceptsStringIdentifier() async throws {
        let data = Data("{\"id\":\"b21c0795-5865-4e3f-a2c4-f05232a4f74b\"}".utf8)
        let dto = try JSONDecoder().decode(QaseAPIResourceDTO.self, from: data)

        #expect(dto.id == .string("b21c0795-5865-4e3f-a2c4-f05232a4f74b"))
    }

    @Test("Qase user DTO decodes title and numeric status")
    func checkUserDTOFields() async throws {
        let data = Data(
            "{\"id\":12,\"name\":\"Ada\",\"email\":\"ada@example.com\",\"title\":\"QA\",\"status\":1}"
                .utf8
        )
        let user = try JSONDecoder().decode(QaseAPIUserDTO.self, from: data)

        #expect(user.title == "QA")
        #expect(user.status == 1)
    }

    @Test("Project access DTO uses member_id")
    func checkProjectAccessRequestEncoding() async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(QaseAPIProjectAccessRequest(memberId: 12))
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Int])

        #expect(json["member_id"] == 12)
        #expect(json["members"] == nil)
    }

    @Test("Milestone status encodes as a Qase string enum")
    func checkMilestoneStatusEncoding() async throws {
        let data = try JSONEncoder().encode(QaseAPIMilestoneUpdateRequest(status: .completed))
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])

        #expect(json["status"] == "completed")
    }

    @Test("Create DTOs encode required request fields")
    func checkRequiredCreateDTOs() async throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let run = try JSONSerialization
            .jsonObject(with: encoder.encode(QaseAPIRunCreateRequest(title: "Run"))) as? [String: Any]
        let result = try JSONSerialization
            .jsonObject(with: encoder.encode(QaseAPIResultCreateRequest(status: "passed"))) as? [String: Any]
        let suite = try JSONSerialization
            .jsonObject(with: encoder.encode(QaseAPISuiteCreateRequest(title: "Suite"))) as? [String: Any]
        let plan = try JSONSerialization.jsonObject(with: encoder.encode(QaseAPIPlanCreateRequest(
            title: "Plan",
            cases: []
        ))) as? [String: Any]
        let sharedParameter = try JSONSerialization.jsonObject(with: encoder.encode(
            QaseAPISharedParameterCreateRequest(
                title: "Browser",
                type: .single,
                projectCodes: nil,
                isEnabledForAllProjects: true,
                parameters: [.object(["value": .string("Chrome")])]
            )
        )) as? [String: Any]

        #expect(run?["title"] as? String == "Run")
        #expect(result?["status"] as? String == "passed")
        #expect(suite?["title"] as? String == "Suite")
        #expect(plan?["cases"] != nil)
        #expect(sharedParameter?["is_enabled_for_all_projects"] as? Bool == true)
    }

    @Test("Successful response parse errors keep the decoding reason")
    func checkResponseDecodingError() async throws {
        do {
            _ = try API.decodeResponse(from: Data("{}".utf8), as: ProjectDataModel.self)
            #expect(Bool(false))
        } catch API.NetError.parsingError(let message) {
            #expect(!message.isEmpty)
        }
    }

    @Test("Multipart builder escapes filenames and enforces file count")
    func checkMultipartBodySafety() async throws {
        let file = API.UploadFile(
            data: Data("content".utf8),
            fileName: "report\"\r\nX-Qase: injected.txt",
            mimeType: "text/plain"
        )
        let body = try API.makeMultipartBody(files: [file], boundary: "test-boundary")
        let bodyText = try #require(String(data: body, encoding: .utf8))

        #expect(!bodyText.contains("\r\nX-Qase: injected"))

        do {
            _ = try API.makeMultipartBody(files: Array(repeating: file, count: 21), boundary: "test-boundary")
            #expect(Bool(false))
        } catch API.NetError.invalidRequest {
            #expect(Bool(true))
        }
    }

    @Test("Qase request DTO encodes API snake case keys")
    func checkRunRequestEncoding() async throws {
        let request = QaseAPIRunCreateRequest(title: "Smoke", includeAllCases: true)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["include_all_cases"] as? Bool == true)
    }

    @Test("Qase rate limit response retains Retry-After")
    func checkRateLimitError() async throws {
        let response = try #require(HTTPURLResponse(
            url: URL(string: "https://api.qase.io/v1/run/DEMO")!,
            statusCode: 429,
            httpVersion: nil,
            headerFields: ["Retry-After": "12"]
        ))
        let data = Data("{\"status\":false,\"errorMessage\":\"Slow down\"}".utf8)
        let error = try #require(API.httpError(from: response, data: data))

        if case .httpError(let statusCode, let message, let retryAfter) = error {
            #expect(statusCode == 429)
            #expect(message == "Slow down")
            #expect(retryAfter == 12)
        } else {
            #expect(Bool(false))
        }
    }

    @Test func checkFirstProjectTitle() async throws {
        let dataURL = apiManager.composeURL(for: .project, urlComponents: nil)!
        let projectsData = try await apiManager.performRequest(
            from: dataURL,
            method: .get,
            modelType: ProjectDataModel.self
        )
        let projects = projectsData.result.entities

        #expect(projects.count == 2)
        #expect(projects[0].title == "Demo Project")
        #expect(projects[1].title == "1Forma")
    }
}
