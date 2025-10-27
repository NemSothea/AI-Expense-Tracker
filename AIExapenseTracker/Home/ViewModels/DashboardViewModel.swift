//
//  DashboardViewModel.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 20/10/25.
//

import Foundation
import Observation

@Observable
class DashboardViewModel {
    private let expenseService = ExpenseService.shared
    private let authManager = AuthManager.shared
    
    var dashboardData: DashboardResponse?
    var isLoading = false
    var error: String?
    var shouldShowLogin = false
    
    @MainActor
    func loadDashboard() async {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            dashboardData = try await expenseService.getDashboard()
        } catch let networkError as NetworkError {
            if networkError.isUnauthorized {
                // Token expired, try to refresh
                await handleTokenRefreshAndRetry()
            } else {
                await handleNetworkError(networkError)
            }
        } catch {
            self.error = "Failed to load dashboard"
        }
    }
    @MainActor
    private func handleNetworkError(_ error: NetworkError) async {
        if error.isUnauthorized {
            await handleTokenRefreshAndRetry()
        } else {
            self.error = error.localizedDescription
        }
    }
    
    @MainActor
        private func handleTokenRefreshAndRetry() async {
            do {
                let refreshSuccess = try await authManager.refreshToken()
                if refreshSuccess {
                    // Retry the dashboard request with new token
                    dashboardData = try await expenseService.getDashboard()
                    error = nil
                } else {
                    error = "Session expired. Please login again."
                    shouldShowLogin = true
                    // Trigger logout after a delay to show the message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.authManager.logout()
                    }
                }
            } catch {
                self.error = "Session expired. Please login again."
                shouldShowLogin = true
                // Trigger logout after a delay to show the message
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.authManager.logout()
                }
            }
        }
        
        func clearError() {
            error = nil
            shouldShowLogin = false
        }
}
