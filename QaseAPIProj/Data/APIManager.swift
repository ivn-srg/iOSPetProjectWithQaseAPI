//
//  NetworkService.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 13.01.2024.
//

import Foundation

final class APIManager {
    static let shared = APIManager()

    func fetchDataNew<T: Decodable>(
        from urlString: String,
        method: String,
        modelType: T.Type
    ) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue(Constants.TOKEN, forHTTPHeaderField: "Token")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let result = try JSONDecoder().decode(modelType, from: data)
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
    
    func fetchData<T: Decodable>(
        from urlString: String,
        method: String,
        modelType: T.Type,
        completion: @escaping (Result<T, Error>
        ) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue(Constants.TOKEN, forHTTPHeaderField: "Token")

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                do {
                    let result = try JSONDecoder().decode(modelType, from: data)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
    
    func updateTestCaseData<T: Decodable>(
        newData: TestEntity,
        from urlString: String,
        method: String,
        modelType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }

        let jsonData: Data
        do {
            jsonData = try JSONEncoder().encode(newData)
        } catch {
            print("Ошибка сериализации: \(error)")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue(Constants.TOKEN, forHTTPHeaderField: "Token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(modelType, from: data)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
    
    func createorUpdateEntity<T: Decodable, U: Encodable>(
        newData: U,
        from urlString: String,
        method: String,
        modelType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }

        let jsonData: Data
        do {
            jsonData = try JSONEncoder().encode(newData)
        } catch {
            print("Ошибка сериализации: \(error)")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue(Constants.TOKEN, forHTTPHeaderField: "Token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(modelType, from: data)
                    completion(.success(result))
                } catch {
                    completion(.failure(error))
                    print("Оригинальный ответ: \(String(data: data, encoding: .utf8) ?? "пустой")")
                }
            }
        }
        task.resume()
    }
    
    func deleteEntity<T: Decodable>(
        from urlString: String,
        method: String,
        modelType: T.Type,
        completion: @escaping (Result<T, Error>) -> Void
    ) async {
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
          "accept": "application/json",
          "content-type": "application/json"
        ]

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(modelType, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        } catch {
            completion(.failure(error))
        }
    }
}

enum APIError: Error {
    case invalidURL, parsingError(Error), noInternetConnection, timeout, otherNetworkError(Error)
}
