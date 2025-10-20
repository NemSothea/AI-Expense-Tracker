//
//  LoginViewModel.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 20/10/25.
//


import SwiftUI
import Alamofire

@MainActor
final class LoginViewModel: ObservableObject {
    
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var email: String = ""
    @Published var password: String = ""
    
    private nonisolated let baseURL: String = "http://localhost:8080"
    private nonisolated let networkService: NetworkService
    
    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }
    
    func login() async -> Bool {
        guard validateInputs() else { return false }
        
        isLoading = true
        error = nil
        
        defer {
            isLoading = false
        }
        
        do {
            let loginResponse = try await networkService.login(
                email: email,
                password: password
            )
            await saveAuthData(loginResponse)
            return true
        } catch let networkError as NetworkError {
            error = networkError.localizedDescription
            return false
        } catch {
            print("An unexpected error occurred")
            return false
        }
    }
    
    private func validateInputs() -> Bool {
        guard !email.isEmpty, !password.isEmpty else {
            error = "Please enter email and password"
            return false
        }
        
        guard isValidEmail(email) else {
            error = "Please enter a valid email address"
            return false
        }
        
        guard password.count >= 4 else {
            error = "Password must be at least 4 characters"
            return false
        }
        
        return true
    }
    
    nonisolated private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #/^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/#
        return (try? emailRegex.wholeMatch(in: email)) != nil
    }
    
    private func saveAuthData(_ loginResponse: LoginResponse) {
        AuthManager.shared.saveAuthData(loginResponse)
    }
}

// MARK: - Network Service
actor NetworkService {
    static let shared = NetworkService()
    private nonisolated let baseURL: String = "http://localhost:8080"
    
    private init() {}
    
    func login(email: String, password: String) async throws -> LoginResponse {
        let parameters: [String: String] = [
            "email": email,
            "password": password
        ]
        
        
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(
                "\(baseURL)/auth/login",
                method: .post,
                parameters: parameters,
                encoder: JSONParameterEncoder.default
            )
            .validate()
            .responseDecodable(of: LoginResponse.self) { response in
                switch response.result {
                case .success(let loginResponse):
                    continuation.resume(returning: loginResponse)
                case .failure(let error):
                    if let data = response.data,
                       let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        continuation.resume(throwing: NetworkError.serverError(errorResponse.message ?? "Login failed"))
                    } else {
                        continuation.resume(throwing: NetworkError.alamofireError(error))
                    }
                }
            }
        }
    }
}



