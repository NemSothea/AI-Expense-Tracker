//
//  AuthManager.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 20/10/25.
//
import Foundation

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    
    private init() {
        checkExistingAuth()
    }
    
    func saveAuthData(_ loginResponse: LoginResponse) {
        UserDefaults.standard.set(loginResponse.token, forKey: "authToken")
        
        if let userData = try? JSONEncoder().encode(loginResponse.user) {
            UserDefaults.standard.set(userData, forKey: "userData")
        }
        
        currentUser = loginResponse.user
        isLoggedIn = true
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "userData")
        isLoggedIn = false
        currentUser = nil
    }
    
    nonisolated func getAuthToken() -> String? {
        UserDefaults.standard.string(forKey: "authToken")
    }
    
    private func checkExistingAuth() {
        if let token = UserDefaults.standard.string(forKey: "authToken"),
           let userData = UserDefaults.standard.data(forKey: "userData"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isLoggedIn = true
        }
    }
}
