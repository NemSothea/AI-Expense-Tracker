//
//  Category+Mapping.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 20/10/25.
//

import Foundation

extension Category {
    var backendId: Int {
        switch self {
        case .Drink: return 1
        case .accountingAndLegalFees: return 2
        case .bankFees: return 3
        case .consultantsAndProfessionalServices: return 4
        case .depreciation: return 5
        case .employeeBenefits: return 6
        case .employeeExpenses: return 7
        case .entertainment: return 8
        case .food: return 9
        case .gifts: return 10
        case .health: return 11
        case .insurance: return 12
        case .interest: return 13
        case .learning: return 14
        case .licensingFees: return 15
        case .marketing: return 16
        case .membershipFees: return 17
        case .officeSupplies: return 18
        case .payroll: return 19
        case .repairs: return 20
        case .rent: return 21
        case .rentOrMortgagePayments: return 22
        case .software: return 23
        case .tax: return 24
        case .travel: return 25
        case .utilities: return 26
        }
    }
    
    static func fromBackendName(_ name: String) -> Category {
        switch name {
        case "Drink": return .Drink
        case "Accounting and legal fees": return .accountingAndLegalFees
        case "Bank fees": return .bankFees
        case "Consultants and professional services": return .consultantsAndProfessionalServices
        case "Depreciation": return .depreciation
        case "Employee benefits": return .employeeBenefits
        case "Employee expenses": return .employeeExpenses
        case "Entertainment": return .entertainment
        case "Food": return .food
        case "Gifts": return .gifts
        case "Health": return .health
        case "Insurance": return .insurance
        case "Interest": return .interest
        case "Learning": return .learning
        case "Licensing fees": return .licensingFees
        case "Marketing": return .marketing
        case "Membership fees": return .membershipFees
        case "Office supplies": return .officeSupplies
        case "Payroll": return .payroll
        case "Repairs": return .repairs
        case "Rent": return .rent
        case "Rent or mortgage payments": return .rentOrMortgagePayments
        case "Software": return .software
        case "Tax": return .tax
        case "Travel": return .travel
        case "Utilities": return .utilities
        default: return .utilities
        }
    }
    
    static func fromBackendId(_ id: Int) -> Category {
        switch id {
        case 1: return .Drink
        case 2: return .accountingAndLegalFees
        case 3: return .bankFees
        case 4: return .consultantsAndProfessionalServices
        case 5: return .depreciation
        case 6: return .employeeBenefits
        case 7: return .employeeExpenses
        case 8: return .entertainment
        case 9: return .food
        case 10: return .gifts
        case 11: return .health
        case 12: return .insurance
        case 13: return .interest
        case 14: return .learning
        case 15: return .licensingFees
        case 16: return .marketing
        case 17: return .membershipFees
        case 18: return .officeSupplies
        case 19: return .payroll
        case 20: return .repairs
        case 21: return .rent
        case 22: return .rentOrMortgagePayments
        case 23: return .software
        case 24: return .tax
        case 25: return .travel
        case 26: return .utilities
        default: return .utilities
        }
    }
}
