//
//  DataBaseManager.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import Foundation
import FirebaseFirestore

final class DatabaseManager : @unchecked Sendable {
    
    static let shared = DatabaseManager()
    
    private init() {}
    
    private(set) lazy var logsCollection : CollectionReference = {
        Firestore.firestore().collection("logs")
    }()
    
    func add(log : ExpenseLog) throws {
        try logsCollection.document(log.id).setData(from: log)
    }
    
    func update(log : ExpenseLog) {
        logsCollection.document(log.id).updateData([
            "name" : log.name,
            "amount":log.amount,
            "category":log.category,
            "date":log.date
        ])
    }
    func delete(log : ExpenseLog) {
        logsCollection.document(log.id).delete()
    }
    
}

// MARK: - Update DatabaseManager for better compatibility
extension DatabaseManager {
    
    func getLogs(completion: @escaping ([ExpenseLog]?, Error?) -> Void) {
        logsCollection
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                
                let logs = documents.compactMap { document in
                    try? document.data(as: ExpenseLog.self)
                }
                
                completion(logs, nil)
            }
    }
    
    func getLogsByDateRange(from startDate: Date, to endDate: Date, completion: @escaping ([ExpenseLog]?, Error?) -> Void) {
        logsCollection
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .whereField("date", isLessThanOrEqualTo: endDate)
            .order(by: "date", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion([], nil)
                    return
                }
                
                let logs = documents.compactMap { document in
                    try? document.data(as: ExpenseLog.self)
                }
                
                completion(logs, nil)
            }
    }
}
extension DatabaseManager {
    
    func getLogsPaginated(
        pageSize: Int,
        lastDocument: DocumentSnapshot? = nil,
        sortBy: String = "date",
        descending: Bool = true,
        categories: [String]? = nil,
        completion: @escaping ([ExpenseLog]?, DocumentSnapshot?, Error?) -> Void
    ) {
        var query: Query = logsCollection
            .order(by: sortBy, descending: descending)
            .limit(to: pageSize)
        
        // Apply category filter
        if let categories = categories, !categories.isEmpty {
            query = query.whereField("category", in: categories)
        }
        
        // Apply pagination
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        query.getDocuments { snapshot, error in
            if let error = error {
                completion(nil, nil, error)
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion([], nil, nil)
                return
            }
            
            let logs = documents.compactMap { document in
                try? document.data(as: ExpenseLog.self)
            }
            
            let lastDocument = documents.last
            completion(logs, lastDocument, nil)
        }
    }
    
    func getTotalCount(categories: [String]? = nil, completion: @escaping (Int?, Error?) -> Void) {
        var query: Query = logsCollection
        
        if let categories = categories, !categories.isEmpty {
            query = query.whereField("category", in: categories)
        }
        
        query.getDocuments { snapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            completion(snapshot?.count, nil)
        }
    }
}
