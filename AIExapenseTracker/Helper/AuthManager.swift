//
//  AuthManager.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 20/10/25.
//
import Foundation
import SimpleKeychain

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    var isSessionExpired = false
    
    private let keychain = KeychainService()
    
    private init() {
        checkExistingAuth()
    }
    
    func saveAuthData(_ loginResponse: LoginResponse, password: String? = nil) {
        // Save token to Keychain
        keychain.saveToken(loginResponse.token)
        
        // Save password to Keychain if provided
        if let password = password {
            keychain.savePassword(password)
        }
        
        // Save user data to UserDefaults (non-sensitive data)
        if let userData = try? JSONEncoder().encode(loginResponse.user) {
            UserDefaults.standard.set(userData, forKey: "userData")
        }
        
        currentUser = loginResponse.user
        isLoggedIn = true
    }
    
    func logout(isSessionExpired: Bool = false) {
        keychain.deleteToken()
        UserDefaults.standard.removeObject(forKey: "userData")
        self.isSessionExpired = isSessionExpired
        isLoggedIn = false
        currentUser = nil        
    }
    
    nonisolated func getAuthToken() -> String? {
        KeychainService().getToken()
    }
    
    private func checkExistingAuth() {
        if let _ = keychain.getToken(),
           let userData = UserDefaults.standard.data(forKey: "userData"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isLoggedIn = true
        }
    }
    
    func refreshToken() async throws -> Bool {
        guard let email = currentUser?.email,
              let password = keychain.getPassword() else {
            return false
        }
        
        do {
            let loginResponse = try await NetworkService.shared.login(
                email: email,
                password: password
            )
            saveAuthData(loginResponse)
            return true
        } catch {
            logout()
            throw error
        }
    }
}

// Keychain Service
class KeychainService {
    private let keychain = SimpleKeychain()
    private let tokenKey = "authToken"
    private let passwordKey = "userPassword"
    
    func saveToken(_ token: String) {
        try? keychain.set(token, forKey: tokenKey)
    }
    
    func getToken() -> String? {
        try? keychain.string(forKey: tokenKey)
    }
    
    func deleteToken() {
        try? keychain.deleteItem(forKey: tokenKey)
    }
    
    func savePassword(_ password: String) {
        try? keychain.set(password, forKey: passwordKey)
    }
    
    func getPassword() -> String? {
        try? keychain.string(forKey: passwordKey)
    }
    
    func deletePassword() {
        try? keychain.deleteItem(forKey: passwordKey)
    }
}
