//
//  AuthManager.swift
//  QaseAPIProj
//
//  Created by Sergey Ivanov on 24.10.2024.
//

import UIKit
import Security

enum AuthState: String {
    case loggedIn = "loggedIn"
    case loggedOutb = "loggedOut"
}

enum KeychainError: Error {
    case noToken
    case unexpectedTokenData
    case unhandledError(status: OSStatus)
}

final class AuthManager {
    static let shared = AuthManager()
    
    private let userDefaults = UserDefaults.standard
    private let authStatusKey = "isUserLoggedIn"
    private let keychain = KeychainService.shared
    private let apiManager = APIManager.shared

    func isUserLoggedIn() -> Bool {
        userDefaults.bool(forKey: authStatusKey)
    }

    func getAuthToken() -> String? {
        keychain.getToken()
    }

    func loggedIn(token: String?) async throws {
        guard let token else {
            try keychain.deleteToken()
            userDefaults.set(false, forKey: authStatusKey)
            notifyAuthStatusChanged()
            return
        }

        let authStatusCheck = try await apiManager.auth(by: token)
        guard authStatusCheck else {
            throw API.NetError.invalidCredantials
        }

        try keychain.saveToken(token: token)
        userDefaults.set(true, forKey: authStatusKey)
        notifyAuthStatusChanged()
    }

    func logout() async throws {
        try await loggedIn(token: nil)
    }

    private func notifyAuthStatusChanged() {
        Task { @MainActor in
            NotificationCenter.default.post(name: .didChangeAuthStatus, object: nil)
        }
    }
}

private class KeychainService {
    static let shared = KeychainService()
    private let key = "authToken"
    private let server = API.BASE_URL
    
    func saveToken(token: String) throws {
        // delete old token if it exists
        try deleteToken()
        
        let tokenData = token.data(using: .utf8)!
        
        // adding new token
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key,
                                    kSecAttrLabel as String: key,
                                    kSecValueData as String: tokenData]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    }
    
    func getToken() -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key,
                                    kSecAttrLabel as String: key,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess else { return nil }
        
        guard
            let existingItem = item as? [String : Any],
            let tokenData = existingItem[kSecValueData as String] as? Data,
            let token = String(data: tokenData, encoding: String.Encoding.utf8)
        else { return nil }
        return token
    }
    
    func deleteToken() throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key,
                                    kSecAttrLabel as String: key]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
    }
}

