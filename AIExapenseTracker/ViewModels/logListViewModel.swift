//
//  logListViewModel.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import Foundation
import Observation
import FirebaseFirestore

@Observable
class LogListViewModel {
    
    let db = DatabaseManager.shared
    
    var sortType = SortType.date
    var sortOrder = SortOrder.descending
    var selectedCategories = Set<Category>()
    var isLogFormPresented: Bool = false
    var logToEdit: ExpenseLog?
    
    // Pagination properties
    var pageSize = 10
    var currentPage = 1
    var isLoading = false
    var hasMoreData = true
    var lastDocumentSnapshot: DocumentSnapshot?
    
    var predicates: [QueryPredicate] {
        var predicates: [QueryPredicate] = []
        
        // Apply category filter if selected
        if !selectedCategories.isEmpty {
            predicates.append(.whereField("category", isIn: Array(selectedCategories).map { $0.rawValue }))
        }
        
        // Apply sorting
        predicates.append(.order(by: sortType.rawValue, descending: sortOrder == .descending))
        
        // Apply pagination limit
        predicates.append(.limit(to: pageSize * currentPage))
        
        return predicates
    }
    
    func loadNextPage() {
        guard !isLoading && hasMoreData else { return }
        
        isLoading = true
        currentPage += 1
    }
    
    func resetPagination() {
        currentPage = 1
        hasMoreData = true
        isLoading = false
        lastDocumentSnapshot = nil
    }
    
}
