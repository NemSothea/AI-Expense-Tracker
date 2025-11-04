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
        print("🔄 loadDashboard started")
        
        isLoading = true
        error = nil
        
        defer {
            isLoading = false
            print("🔄 loadDashboard finished")
        }
        
        do {
            dashboardData = try await expenseService.getDashboard(startDate: nil, endDate: nil)
            
        } catch let networkError as NetworkError {
            if networkError.isUnauthorized {
                // Token expired, try to refresh
                await handleTokenRefreshAndRetry()
            } else {
                dashboardData = nil
                await handleNetworkError(networkError)
            }
        } catch let urlError as URLError {
            dashboardData = nil
            await handleURLError(urlError)
        } catch {
            dashboardData = nil
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
    private func handleURLError(_ urlError: URLError) async {
        switch urlError.code {
        case .cannotConnectToHost: // Error -1004
            self.error = "Cannot connect to server. Please check:\n• Server is not running."
            
        case .notConnectedToInternet:
            self.error = "No internet connection. Please check your network."
            
        case .timedOut:
            self.error = "Connection timed out. Server might be busy."
            
        case .cannotFindHost:
            self.error = "Cannot find the server. Please check the server address."
            
        default:
            self.error = "Network error: \(urlError.localizedDescription)"
        }
    }

    
    @MainActor
        private func handleTokenRefreshAndRetry() async {
            do {
                let refreshSuccess = try await authManager.refreshToken()
                if refreshSuccess {
                    // Retry the dashboard request with new token
                    dashboardData = try await expenseService.getDashboard(startDate: nil, endDate: nil)
                    error = nil
                } else {
                    self.error = (error as? NetworkError)?.localizedDescription ?? "Session expired. Please login again."
                    shouldShowLogin = true
                    // Trigger logout after a delay to show the message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.authManager.logout()
                    }
                }
            } catch {
              
                self.error = (error as? NetworkError)?.localizedDescription ?? "Session expired. Please login again."
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
