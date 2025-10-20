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
    
    var dashboardData: DashboardResponse?
    var isLoading = false
    var error: String?
    
    @MainActor
    func loadDashboard() async {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            dashboardData = try await expenseService.getDashboard()
        } catch {
            self.error = (error as? NetworkError)?.localizedDescription ?? "Failed to load dashboard"
        }
    }
}
