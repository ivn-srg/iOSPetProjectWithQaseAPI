//
//  NetworkService.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 13.01.2024.
//

import Foundation

protocol NetworkManager: AnyObject {
    func performRequest<T: Decodable>(
        with data: Encodable?,
        from urlString: String,
        method: HTTPMethod,
        modelType: T.Type
    ) async throws -> T
    
    func makeHTTPRequest<T: Decodable>(
        for request: URLRequest,
        codableModelType: T.Type
    ) async throws -> T
}

final class APIManager: NetworkManager {
    static let shared = APIManager()
    
    let DOMEN = "https://api.qase.io/v1"
    
    func performRequest<T: Decodable>(
        with data: Encodable? = nil,
        from urlString: String,
        method: HTTPMethod,
        modelType: T.Type
    ) async throws(APIError) -> T {
        guard let url = URL(string: urlString) else { throw .invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue(TOKEN, forHTTPHeaderField: "Token")
        
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
    
    func makeHTTPRequest<T: Decodable>(
        for request: URLRequest,
        codableModelType: T.Type
    ) async throws(APIError) -> T {
        var errorMessage = ""
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            do {
                let result = try JSONDecoder().decode(codableModelType, from: data)
                return result
            } catch {
                let errorModel = try JSONDecoder().decode(ResponseWithErrorModel.self, from: data)
                
                errorMessage = errorModel.errorMessage != nil
                ? errorModel.errorMessage!
                : errorModel.message != nil ? errorModel.message! : ""
            }
            throw APIError.parsingError(errorMessage)
        } catch let error as DecodingError {
            throw .parsingError(error.errorDescription ?? error.localizedDescription)
        } catch {
            guard errorMessage.isEmpty else { throw .parsingError(errorMessage) }
            throw .otherNetworkError(error.localizedDescription)
        }
    }
    
    func formUrlString(
        APIMethod: APIEndpoint,
        codeOfProject: String?,
        limit: Int? = nil,
        offset: Int? = nil,
        parentSuite: ParentSuite? = nil,
        suiteId: Int? = nil,
        caseId: Int? = nil
    ) -> String? {
        
        switch APIMethod {
        case .project:
            if let limit = limit, let offset = offset {
                return "\(DOMEN)/project?limit=\(limit)&offset=\(offset)"
            } else if let codeOfProject = codeOfProject {
                return "\(DOMEN)/project/\(codeOfProject)"
            } else {
                return "\(DOMEN)/project"
            }
        case .suites:
            guard let codeOfProject = codeOfProject else { return nil }
            guard let limit = limit, let offset = offset else {
                if let suiteId = suiteId {
                    return "\(DOMEN)/suite/\(codeOfProject)/\(suiteId)"
                } else {
                    return "\(DOMEN)/suite/\(codeOfProject)"
                }
            }
            guard let parentSuite = parentSuite else {
                return "\(DOMEN)/suite/\(codeOfProject)?limit=\(limit)&offset=\(offset)"
            }
            guard
                let searchSuiteString = parentSuite.title.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            else { return nil }
            
            return "\(DOMEN)/suite/\(codeOfProject)?search=\"\(searchSuiteString)\"&limit=\(limit)&offset=\(offset)"
        case .cases:
            guard let codeOfProject = codeOfProject else { return nil }
            guard let limit = limit, let offset = offset else {
                if let caseId = caseId {
                    return "\(DOMEN)/case/\(codeOfProject)/\(caseId)"
                } else {
                    return "\(DOMEN)/case/\(codeOfProject)"
                }
            }
            guard let parentSuite = parentSuite else {
                return "\(DOMEN)/case/\(codeOfProject)?limit=\(limit)&offset=\(offset)"
            }
            
            return "\(DOMEN)/case/\(codeOfProject)?suite_id=\(parentSuite.id)&limit=\(limit)&offset=\(offset)"
        case .openedCase:
            guard let codeOfProject = codeOfProject else { return nil }
            guard let caseId = caseId else { return nil }
            
            return "\(DOMEN)/case/\(codeOfProject)/\(caseId)"
        }
    }
}

enum APIError: Error {
    case invalidURL, parsingError(String), serializationError(String),
         noInternetConnection, timeout, otherNetworkError(String)
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum APIEndpoint: String, CaseIterable {
    case project = "project"
    case suites = "suite"
    case cases = "case"
    case openedCase = ""
    
    func returnAllEnumCases() -> [String] {
        var listOfCases = [String]()
        
        for caseValue in APIEndpoint.allCases {
            listOfCases.append(caseValue.rawValue)
        }
        
        return listOfCases
    }
}
