//
//  NetworkService.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 13.01.2024.
//

import Foundation

final class APIManager {
    static let shared = APIManager()

    func fetchData<T: Decodable>(
        from urlString: String,
        method: String,
        modelType: T.Type
    ) async throws -> T {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue(Constants.TOKEN, forHTTPHeaderField: "Token")
        
        return try await makeHTTPRequest(for: request, codableModelType: modelType)
    }
    
    func createorUpdateEntity<T: Decodable, U: Encodable>(
        newData: U,
        from urlString: String,
        method: String,
        modelType: T.Type
    ) async throws -> T {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        let jsonData: Data
        do {
            jsonData = try JSONEncoder().encode(newData)
        } catch let error as EncodingError {
            throw APIError.serializationError(error)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue(Constants.TOKEN, forHTTPHeaderField: "Token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        return try await makeHTTPRequest(for: request, codableModelType: modelType)
    }
    
    func deleteEntity<T: Decodable>(
        from urlString: String,
        method: String,
        modelType: T.Type
    ) async throws -> T {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
          "accept": "application/json",
          "content-type": "application/json"
        ]
        
        return try await makeHTTPRequest(for: request, codableModelType: modelType)
    }
    
    private func makeHTTPRequest<T: Decodable>(
        for request: URLRequest,
        codableModelType: T.Type
    ) async throws -> T {
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let result = try JSONDecoder().decode(codableModelType, from: data)
            return result
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
}

enum APIError: Error {
    case invalidURL, parsingError(Error), serializationError(Error), noInternetConnection, timeout, otherNetworkError(Error)
}
