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
    
    // Alternative predicates for manual pagination with startAfter
    var paginatedPredicates: [QueryPredicate] {
        var predicates: [QueryPredicate] = []
        
        // Apply category filter if selected
        if !selectedCategories.isEmpty {
            predicates.append(.whereField("category", isIn: Array(selectedCategories).map { $0.rawValue }))
        }
        
        // Apply sorting
        predicates.append(.order(by: sortType.rawValue, descending: sortOrder == .descending))
        
        // Apply pagination
        predicates.append(.limit(to: pageSize))
        
        // Start after last document for pagination
        let limit = pageSize * currentPage
        predicates.append(.limit(to: limit))
        
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
    
    // Manual pagination method using DatabaseManager
    func loadNextPageManually(completion: @escaping ([ExpenseLog]?) -> Void) {
        guard !isLoading && hasMoreData else { return }
        
        isLoading = true
        
        let query = db.logsCollection
            .order(by: sortType.rawValue, descending: sortOrder == .descending)
            .limit(to: pageSize)
        
        if let lastDoc = lastDocumentSnapshot {
            query.start(afterDocument: lastDoc)
        }
        
        if !selectedCategories.isEmpty {
            let categories = Array(selectedCategories).map { $0.rawValue }
            query.whereField("category", in: categories)
        }
        
        query.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error loading next page: \(error)")
                self.isLoading = false
                completion(nil)
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.hasMoreData = false
                self.isLoading = false
                completion([])
                return
            }
            
            let newLogs = documents.compactMap { document in
                try? document.data(as: ExpenseLog.self)
            }
            
            self.lastDocumentSnapshot = documents.last
            self.hasMoreData = newLogs.count == self.pageSize
            self.isLoading = false
            
            completion(newLogs)
        }
    }
}
