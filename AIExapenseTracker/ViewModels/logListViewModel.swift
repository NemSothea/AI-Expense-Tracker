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
    
    
    var predicates : [QueryPredicate] {
        var predicates: [QueryPredicate] = [QueryPredicate]()
        if selectedCategories.count > 0 {
            
            predicates.append(.whereField("category", isIn: Array(selectedCategories).map{$0.rawValue}))
                              
        }
        
        predicates.append(.order(by: sortType.rawValue, descending: sortOrder == .descending ? true : false))
        return predicates
    }
    
    
}
