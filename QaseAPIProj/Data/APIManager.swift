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
        from urlString: URL?,
        method: API.HTTPMethod,
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
        from urlString: URL?,
        method: API.HTTPMethod,
        modelType: T.Type
    ) async throws(API.NetError) -> T {
        guard let url = urlString else { throw .invalidURL }
        
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
    ) async throws(API.NetError) -> T {
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
            throw API.NetError.parsingError(errorMessage)
        } catch let error as DecodingError {
            throw .parsingError(error.errorDescription ?? error.localizedDescription)
        } catch {
            guard errorMessage.isEmpty else { throw .parsingError(errorMessage) }
            throw .otherNetworkError(error.localizedDescription)
        }
    }
    
    func composeURL(for method: API.Endpoint, urlComponents: [String?]?, queryItems: [API.QueryParams: Int?]? = nil) -> URL? {
        
        var resultUrl = URL(string: "\(DOMEN)/\(method.rawValue)")
        
        if let urlComponents = urlComponents {
            for component in urlComponents {
                guard let component = component else { continue }
                
                resultUrl = resultUrl?.appendingPathComponent(component)
            }
        }
        
        if let queryItems = queryItems {
            var queryDict = [URLQueryItem]()
            
            for item in queryItems {
                guard let itemValue = item.value else { continue }
                
                queryDict.append(URLQueryItem(name: item.key.rawValue, value: "\(itemValue)"))
            }
            
            resultUrl?.append(queryItems: queryDict)
        }
        
        return resultUrl
    }
}

struct API {
    enum NetError: Error {
        case invalidURL, parsingError(String), serializationError(String),
             noInternetConnection, timeout, otherNetworkError(String)
    }

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    enum Endpoint: String, CaseIterable {
        case project = "project"
        case suites = "suite"
        case cases = "case"
        
        func returnAllEnumCases() -> [String] {
            var listOfCases = [String]()
            
            for caseValue in Self.allCases {
                listOfCases.append(caseValue.rawValue)
            }
            
            return listOfCases
        }
    }
    
    enum QueryParams: String {
        case limit = "limit"
        case offset = "offset"
        case suiteId = "suite_id"
        case search = "search"
    }
}
