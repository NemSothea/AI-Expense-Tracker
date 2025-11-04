//
//  FunctionsManager.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 21/10/25.
//

import Foundation
import ChatGPTSwift

final class FunctionsManager: @unchecked Sendable{
    
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
                        
                        // NEW: fetch from API
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
                        
                        // Reuse same fetcher with only date window
                        let logs = try await fetchLogs(args: .init(
                            date: vizArgs.date,
                            startDate: vizArgs.startDate,
                            endDate: vizArgs.endDate,
                            category: nil,
                            sortOrder: nil,
                            quantityOfLogs: nil
                        ))
                        
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
    
    /// Fetch logs from backend, apply filters (date/category) + sort + limit to match tool args
    func fetchLogs(args: ListExpenseArgs) async throws -> [ExpenseLog] {
        // Desired count, default 100 when no date filter (to mirror old logic)
        let desiredCount: Int = {
            if args.isDateFilterExists { return args.quantityOfLogs ?? 100 }
            return args.quantityOfLogs ?? 100
        }()
        
        // We’ll page from the API until we have enough or run out
        var page = 0
        let pageSize = 50
        var collected: [ExpenseLog] = []
        
        // Precompute optional date window
        let (start, end): (Date?, Date?) = {
            if let s = args.startDate, let e = args.endDate { return (s.startOfDay, e.endOfDay) }
            if let d = args.date { return (d.startOfDay, d.endOfDay) }
            return (nil, nil)
        }()
        
        while collected.count < desiredCount {
            // 1) Pull a page from your backend
            let pageResp = try await db.getExpenses(page: page, size: pageSize)
            if pageResp.content.isEmpty { break }
            
            // 2) Map server Expense -> UI ExpenseLog
            let mapped: [ExpenseLog] = pageResp.content.compactMap { exp in
                exp.asExpenseLog()
            }
            
            // 3) Apply filters client-side (date + category), since the API
            //    pagination endpoint may not support those query params yet.
            let filtered = mapped.filter { log in
                // Date window
                if let s = start, let e = end {
                    guard (s...e).contains(log.date) else { return false }
                }
                // Category name filter (tool gives string)
                if let cat = args.category, !cat.isEmpty {
                    if log.category.caseInsensitiveCompare(cat) != .orderedSame { return false }
                }
                return true
            }
            
            collected.append(contentsOf: filtered)
            page += 1
            if page >= (pageResp.totalPages) { break }
        }
        
        // 4) Sort
        let order = SortOrder(rawValue: args.sortOrder ?? "") ?? .descending
        collected.sort { a, b in
            order == .descending ? (a.date > b.date) : (a.date < b.date)
        }
        
        // 5) Limit
        if collected.count > desiredCount {
            collected = Array(collected.prefix(desiredCount))
        }
        
        return collected
    }
}

extension Expense {
    func asExpenseLog() -> ExpenseLog {
        // Adjust these to your actual model fields
        // Assumptions based on your request/response types:
        // - id: Int
        // - description: String
        // - amount: Double
        // - category: ExpenseCategory?  (with 'name' String) OR 'categoryName' String
        // - expenseDate: String (yyyy-MM-dd)
        
        let date: Date = {
            let df = DateFormatter()
            df.calendar = .init(identifier: .gregorian)
            df.locale = .init(identifier: "en_US_POSIX")
            df.timeZone = .init(secondsFromGMT: 0)
            df.dateFormat = "yyyy-MM-dd"
            return df.date(from: self.expenseDate) ?? .now
        }()
        
        let categoryName: String = {
            if let cat = (self.category as? ExpenseCategory) {
                return cat.name
            }
            // If your model is flat:
            if let name = (self as AnyObject).value(forKey: "categoryName") as? String {
                return name
            }
            return "Utilities" // sensible default
        }()
        
        return ExpenseLog(
            id: String(self.id),
            name: self.description,
            category: categoryName,
            amount: self.amount,
            currency: "USD",      // set if your API returns it; otherwise default
            date: date
        )
    }
}

