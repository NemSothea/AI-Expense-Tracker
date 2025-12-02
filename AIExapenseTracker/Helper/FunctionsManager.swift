//
//  FunctionsManager.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 21/10/25.
//

import Foundation
import ChatGPTSwift

final class FunctionsManager: @unchecked Sendable {
    
    let api: ChatGPTAPI
    let db = ExpenseService.shared
    
    private let callbackLock = NSLock()
    private var _addLogConfirmationCallback: AddExpenseLogConfirmationCallback?
    
    var addLogConfirmationCallback: AddExpenseLogConfirmationCallback? {
        get {
            callbackLock.lock()
            defer { callbackLock.unlock() }
            return _addLogConfirmationCallback
        }
        set {
            callbackLock.lock()
            defer { callbackLock.unlock() }
            _addLogConfirmationCallback = newValue
        }
    }
    
    static let currentDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
    
    let jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .custom({ decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            guard let date = FunctionsManager.currentDateFormatter.date(from: dateString) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "cannot decode date")
            }
            return date
        })
        return jsonDecoder
    }()
    
    var systemText: String {
        "You are expert of tracking and managing expenses logs. Don't make assumptions about what values to plug into functions. Ask for clarification if a user request is ambiguous. Current date is \(Self.currentDateFormatter.string(from: .now))"
    }
    
    init(apiKey: String) {
        self.api = .init(apiKey: apiKey)
    }
    
    func prompt(_ prompt: String, model: ChatGPTModel = .gpt_hyphen_4o, messageID: UUID? = nil) async throws -> AIAssistantResponse {
        do {
            let message = try await api.callFunction(prompt: prompt, tools: tools, model: model, systemText: systemText)
            try Task.checkCancellation()
            
            if let toolCall = message.tool_calls?.first,
               let functionType = AIAssistantFunctionType(rawValue: toolCall.function.name),
               let argumentData = toolCall.function.arguments.data(using: .utf8) {
                
                switch functionType {
                case .addExpenseLog:
                    guard let addLogConfirmationCallback else {
                        throw "Add log confirmation callback is missing"
                    }
                    guard let addExpenseLogArgs = try? self.jsonDecoder.decode(AddExpenseLogArgs.self, from: argumentData) else {
                        throw "Failed to parse function arguments \(toolCall.function.name) \(toolCall.function.arguments)"
                    }
                    let log = ExpenseLog(id: UUID().uuidString, name: addExpenseLogArgs.title, category: addExpenseLogArgs.category, amount: addExpenseLogArgs.amount, currency: addExpenseLogArgs.currency ?? "USD", date: addExpenseLogArgs.date ?? .now)
                    
                    return .init(text: "Please select the confirm button before i add it to your expense list", type: .addExpenseLog(.init(log: log, messageID: messageID, userConfirmation: .pending, confirmationCallback: addLogConfirmationCallback)))
                
                case .listExpenses:
                    guard let listExpenseArgs = try? self.jsonDecoder.decode(ListExpenseArgs.self, from: argumentData) else {
                        throw "Failed to parse function arguments \(toolCall.function.name) \(toolCall.function.arguments)"
                    }
                    
                    let logs = try await fetchLogs(args: listExpenseArgs)
                    let sum = logs.reduce(0, { $0 + $1.amount })
                    let sumText = Utils.numberFormatter.string(from: NSNumber(value: sum)) ?? ""
                    
                    let text: String
                    if listExpenseArgs.isDateFilterExists {
                        text = logs.isEmpty
                        ? "You don't have any expenses at the given date"
                        : "Sure, here's the list of your expenses with total sum of \(sumText)"
                    } else {
                        text = logs.isEmpty
                        ? "You don't have any recent expenses"
                        : "Sure, here's the list of your last \(logs.count) expenses with total sum of \(sumText)"
                    }
                    return .init(text: text, type: .listExpenses(logs))
                    
                case .visualizeExpenses:
                    guard let vizArgs = try? self.jsonDecoder.decode(VisualizeExpenseArgs.self, from: argumentData) else {
                        throw "Failed to parse function arguments \(toolCall.function.name) \(toolCall.function.arguments)"
                    }
                    
                    // Create ListExpenseArgs for visualization
                    let listArgs = ListExpenseArgs(
                        date: vizArgs.date,
                        startDate: vizArgs.startDate,
                        endDate: vizArgs.endDate,
                        category: nil,
                        sortOrder: nil,
                        quantityOfLogs: nil
                    )
                    
                    let logs = try await fetchLogs(args: listArgs)
                    
                    var categorySumDict = [Category: Double]()
                    logs.forEach { log in
                        categorySumDict[log.categoryEnum, default: 0] += log.amount
                    }
                    
                    let chartOptions = categorySumDict.map { Option(category: $0.key, amount: $0.value) }
                    return .init(text: "Sure, here is the visualization of your expenses for each category",
                                 type: .visualizeExpenses(vizArgs.chartTypeEnum, chartOptions))
                        
                default:
                    var text = "Function Name: \(toolCall.function.name)"
                    text += "\nArgs: \(toolCall.function.arguments)"
                    return .init(text: text, type: .contentText)
                }
            } else if let message = message.content {
                api.appendToHistoryList(userText: prompt, responseText: message)
                return .init(text: message, type: .contentText)
            } else {
                throw "Invalid response"
            }
            
        } catch {
            print(error.localizedDescription)
            throw error
        }
    }
}

extension FunctionsManager {
    
    /// Fetch logs from backend with proper filtering, sorting and limiting
    func fetchLogs(args: ListExpenseArgs) async throws -> [ExpenseLog] {
        // Determine the limit - use Firebase-like logic
        let limit: Int = {
            if args.isDateFilterExists {
                return args.quantityOfLogs ?? 100
            } else {
                return args.quantityOfLogs ?? 100
            }
        }()
        
        var page = 0
        let pageSize = 50
        var collected: [ExpenseLog] = []
        
        // Calculate date range for filtering
        let dateRange: (start: Date?, end: Date?) = {
            if let startDate = args.startDate, let endDate = args.endDate {
                return (startDate.startOfDay, endDate.endOfDay)
            } else if let date = args.date {
                return (date.startOfDay, date.endOfDay)
            }
            return (nil, nil)
        }()
        
        // Fetch and filter logs
        while collected.count < limit {
            let pageResp = try await db.getExpenses(page: page, size: pageSize)
            if pageResp.content.isEmpty { break }
            
            // Convert to ExpenseLog and apply filters
         
            let mappedLogs = pageResp.content.compactMap { $0.asExpenseLog() }
            
            let filteredLogs = mappedLogs.filter { log in
                // Date filter
                if let start = dateRange.start, let end = dateRange.end {
                    guard log.date >= start && log.date <= end else { return false }
                }
                
                // Category filter
                if let category = args.category, !category.isEmpty {
                    guard log.category.caseInsensitiveCompare(category) == .orderedSame else { return false }
                }
                
                return true
            }
            
            collected.append(contentsOf: filteredLogs)
            
            // Stop if we've collected enough or reached the end
            if collected.count >= limit || page >= (pageResp.totalPages - 1) {
                break
            }
            
            page += 1
        }
        
        // Apply sorting
        let sortOrder = SortOrder(rawValue: args.sortOrder ?? "") ?? .descending
        collected.sort { a, b in
            switch sortOrder {
            case .ascending:
                return a.date < b.date
            case .descending:
                return a.date > b.date
            }
        }
        
        // Apply final limit
        if collected.count > limit {
            collected = Array(collected.prefix(limit))
        }
        
        return collected
    }
}


extension Expense {
    func asExpenseLog() -> ExpenseLog {
        
        let date: Date = {
            let df = DateFormatter()
            df.calendar = .init(identifier: .gregorian)
            df.locale = .init(identifier: "en_US_POSIX")
            df.timeZone = .init(secondsFromGMT: 0)
            df.dateFormat = "yyyy-MM-dd"
            return df.date(from: self.expenseDate) ?? .now
        }()
       
        let categoryString: String
        
        if let stringCategory = self.category as? String {
            categoryString = stringCategory
        } else {
            // Fallback to categoryName property or default
            categoryString = (self as AnyObject).value(forKey: "categoryName") as? String ?? "Utilities"
        }
               
        
        return ExpenseLog(
            id: String(self.id),
            name: self.description,
            category: categoryString,
            amount: self.amount,
            currency: "USD",
            date: date
        )
    }
}
