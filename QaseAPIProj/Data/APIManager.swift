//
//  NetworkService.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 13.01.2024.
//

import Foundation

final class APIManager {
    static let shared = APIManager()

    func fetchData<T: Decodable>(from urlString: String, method: String, token: String, modelType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue(token, forHTTPHeaderField: "Token")

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
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
    
    func updateTestCaseData<T: Decodable>(newData: TestEntity, from urlString: String, method: String, modelType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
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
}

enum APIError: Error {
    case invalidURL
}
