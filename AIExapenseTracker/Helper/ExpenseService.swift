//
//  ExpenseViewModel.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 20/10/25.
//

import Foundation
import Alamofire

actor ExpenseService {
    static let shared = ExpenseService()
    
    private let baseURL = "http://localhost:8080"
    private let session: Session
    
    private init() {
        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = 30
        session = Session(configuration: configuration)
    }
    
    // MARK: - Auth Helper
    private func getAuthHeaders() -> HTTPHeaders? {
        guard let token = AuthManager.shared.getAuthToken() else {
            return nil
        }
        return [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json",
            "accept": "*/*"
        ]
    }
    
    // MARK: - Dashboard
    func getDashboard() async throws -> DashboardSummary {
        guard let headers = getAuthHeaders() else {
            throw NetworkError.unauthorized
        }
        
        return try await session.request(
            "\(baseURL)/api/dashboard",
            method: .get,
            headers: headers
        )
        .validate()
        .serializingDecodable(DashboardSummary.self)
        .value
    }
    
    // MARK: - Expenses
    func getExpenses(page: Int = 0, size: Int = 20) async throws -> PaginatedResponse<Expense> {
        guard let headers = getAuthHeaders() else {
            throw NetworkError.unauthorized
        }
        
        // Get current user ID from stored user data
        guard let user = await AuthManager.shared.currentUser else {
            throw NetworkError.unauthorized
        }
        
        return try await session.request(
            "\(baseURL)/api/dashboard/history-pagination",
            method: .get,
            parameters: [
                "userId": user.id,
                "page": page,
                "size": size,
                "sort": "expenseDate,desc"
            ],
            headers: headers
        )
        .validate()
        .serializingDecodable(PaginatedResponse<Expense>.self)
        .value
    }
    
    func createExpense(_ request: ExpenseRequest) async throws -> Expense {
        guard let headers = getAuthHeaders() else {
            throw NetworkError.unauthorized
        }
        
        return try await session.request(
            "\(baseURL)/api/create-expenses",
            method: .post,
            parameters: request,
            encoder: JSONParameterEncoder.default,
            headers: headers
        )
        .validate()
        .serializingDecodable(Expense.self)
        .value
    }
    
    func updateExpense(expenseId: Int, request: ExpenseRequest) async throws -> Expense {
        guard let headers = getAuthHeaders() else {
            throw NetworkError.unauthorized
        }
        
        return try await session.request(
            "\(baseURL)/api/create-expenses/\(expenseId)",
            method: .patch,
            parameters: request,
            encoder: JSONParameterEncoder.default,
            headers: headers
        )
        .validate()
        .serializingDecodable(Expense.self)
        .value
    }
    
    func deleteExpense(expenseId: Int) async throws {
        guard let headers = getAuthHeaders() else {
            throw NetworkError.unauthorized
        }
        
        _ = try await session.request(
            "\(baseURL)/api/create-expenses/\(expenseId)",
            method: .delete,
            headers: headers
        )
        .validate()
        .serializingString()
        .value
    }
    
    // MARK: - Categories
    func getActiveCategories() async throws -> [ExpenseCategory] {
        guard let headers = getAuthHeaders() else {
            throw NetworkError.unauthorized
        }
        
        return try await session.request(
            "\(baseURL)/api/categories/active",
            method: .get,
            headers: headers
        )
        .validate()
        .serializingDecodable([ExpenseCategory].self)
        .value
    }
}

extension ExpenseService {
    // MARK: - Dashboard
    func getDashboard(startDate: String? = nil, endDate: String? = nil) async throws -> DashboardResponse {
        guard let headers = getAuthHeaders() else {
            throw NetworkError.unauthorized
        }
        
        guard let user = await AuthManager.shared.currentUser else {
            throw NetworkError.unauthorized
        }
        
        var parameters: [String: Any] = ["userId": user.id]
        
        // Add optional date parameters
        if let startDate = startDate {
            parameters["start"] = startDate
        }
        if let endDate = endDate {
            parameters["end"] = endDate
        }
        
        // Add limits (you can make these parameters too if needed)
        parameters["topLimit"] = 5
        parameters["recentLimit"] = 10
        
        return try await session.request(
            "\(baseURL)/api/dashboard",
            method: .get,
            parameters: parameters,
            headers: headers
        )
        .validate()
        .serializingDecodable(DashboardResponse.self)
        .value
    }
}
