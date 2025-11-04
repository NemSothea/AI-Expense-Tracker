//
//  ExpenseViewModel.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 20/10/25.
//

import Foundation
import Alamofire

actor ExpenseService {
    nonisolated static let shared = ExpenseService()
    
    private let baseURL = "http://localhost:8080"
    private let session: Session
    
    private init() {
        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = 30
        session = Session(configuration: configuration)
    }
    
    // MARK: - Auth Helper
    private func getAuthHeaders() async -> HTTPHeaders? {
        guard let token = await AuthManager.shared.getAuthToken() else {
            return nil
        }
        return [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json",
            "accept": "*/*"
        ]
    }
    
    
    // MARK: - Expenses
    func getExpenses(page: Int = 0, size: Int = 20) async throws -> PaginatedResponse<Expense> {
        guard let headers = await getAuthHeaders() else {
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
        guard let headers = await getAuthHeaders() else {
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
        guard let headers = await getAuthHeaders() else {
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
        guard let headers = await getAuthHeaders() else {
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
        guard let headers = await getAuthHeaders() else {
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
        print("🔍 getDashboard called with dates: \(startDate ?? "nil") to \(endDate ?? "nil")")
            
        guard let headers = await getAuthHeaders() else {
            throw NetworkError.unauthorized
        }
        
        guard let user = await AuthManager.shared.currentUser else {
            throw NetworkError.unauthorized
        }
        
        var parameters: [String: String] = ["userId": String(user.id)]
        
        // Default to last 1 year if no dates provided
        let finalStartDate: String
        let finalEndDate: String
        
        if let startDate = startDate, let endDate = endDate {
            finalStartDate = startDate
            finalEndDate = endDate
        } else {
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            finalStartDate = dateFormatter.string(from: startDate)
            finalEndDate = dateFormatter.string(from: endDate)
        }
        
        parameters["start"] = finalStartDate
        parameters["end"] = finalEndDate
        parameters["topLimit"] = "5"
        parameters["recentLimit"] = "10"
        
        print("🌐 Making request to: \(baseURL)/api/dashboard")
        print("🌐 Parameters: \(parameters)")
        
        do {
            let response = try await session.request(
                "\(baseURL)/api/dashboard",
                method: .get,
                parameters: parameters,
                headers: headers
            )
            .validate()
            .serializingDecodable(DashboardResponse.self)
            .value
            
            print("✅ Dashboard data received successfully")
            return response
            
        } catch let afError as AFError {
            print("❌ AFError: \(afError)")
            let networkError = NetworkError.fromAFError(afError)
            throw networkError
            
        } catch let urlError as URLError {
            print("❌ URLError: \(urlError)")
            let networkError = NetworkError.fromURLError(urlError)
            throw networkError
            
        } catch {
            print("❌ Unknown error: \(error)")
            throw NetworkError.serverError("Unknown error: \(error.localizedDescription)")
        }
    }
}
