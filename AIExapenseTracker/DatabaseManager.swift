//
//  DataBaseManager.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import Foundation
import FirebaseFirestore

class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private init() {}
    
    private (set) lazy var logsCollection : CollectionReference = {
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
