//
//  logListViewModel.swift
//  AIExapenseTracker
//

import Foundation
import Observation

@Observable
class LogListViewModel {

    let db = DatabaseManager.shared

    var sortType = SortType.date
    var sortOrder = SortOrder.descending
    var selectedCategories = Set<Category>()
    var searchText: String = ""
    var isLogFormPresented: Bool = false
    var logToEdit: ExpenseLog?

    // Simple in-memory page counter (no Firestore cursors needed)
    var pageSize = 20
    var currentPage = 1
    var isLoading = false
    var hasMoreData = true

    func loadNextPage() {
        guard !isLoading && hasMoreData else { return }
        isLoading = true
        currentPage += 1
        isLoading = false
    }

    func resetPagination() {
        currentPage = 1
        hasMoreData = true
        isLoading = false
    }
}
