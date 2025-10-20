//
//  LoginModel.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 20/10/25.
//

// MARK: - Response Models
struct LoginResponse: Codable, Sendable {
    let token: String
    let user: User
}

struct User: Codable, Sendable {
    let id: Int
    let name: String
    let email: String
    let role: String
    let contact: String?
    let enabled: Bool
}
