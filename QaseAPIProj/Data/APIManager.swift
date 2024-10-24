//
//  NetworkService.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 13.01.2024.
//

import Foundation

protocol NetworkManager: AnyObject {
    func performRequest<T: Decodable>(
        with data: any Encodable,
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
        with data: any Encodable = Optional<Data>.none,
        from urlString: String,
        method: HTTPMethod,
        modelType: T.Type
    ) async throws -> T {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue(TOKEN, forHTTPHeaderField: "Token")
        
        if !(data is Optional<Data>) {
            let jsonData: Data
            do {
                jsonData = try JSONEncoder().encode(data)
            } catch let error as EncodingError {
                throw APIError.serializationError(error)
            }
            request.httpBody = jsonData
            request.addValue("application/json", forHTTPHeaderField: "content-type")
        }
        
        if method == .delete || method == .get {
            request.addValue("application/json", forHTTPHeaderField: "accept")
        }
        
        return try await makeHTTPRequest(for: request, codableModelType: modelType)
    }
    
    internal func makeHTTPRequest<T: Decodable>(
        for request: URLRequest,
        codableModelType: T.Type
    ) async throws -> T {
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            do {
                let result = try JSONDecoder().decode(codableModelType, from: data)
                return result
            } catch {
                let errorModel = try JSONDecoder().decode(ResponseWithErrorModel.self, from: data)
                let errorMessage = StringError(errorModel.errorMessage)
                throw APIError.parsingError(errorMessage)
            }
        } catch let error as DecodingError {
            throw APIError.parsingError(error)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                throw APIError.noInternetConnection
            case .timedOut:
                throw APIError.timeout
            default:
                throw APIError.otherNetworkError(error)
            }
        } catch {
            throw APIError.otherNetworkError(error)
        }
    }
    
    func formUrlString(
        APIMethod: APIEndpoint,
        codeOfProject: String?,
        limit: Int?,
        offset: Int?,
        parentSuite: ParentSuite?,
        caseId: Int?
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
                return "\(DOMEN)/suite/\(codeOfProject)"
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
                return "\(DOMEN)/case/\(codeOfProject)"
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
    case invalidURL, parsingError(Error), serializationError(Error), noInternetConnection, timeout, otherNetworkError(Error)
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

struct StringError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}

extension StringError: LocalizedError {
    var errorDescription: String? {
        return message
    }
}
