//
//  FilterCategoriesView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import SwiftUI

struct LogItemView: View {
    
   
    let log : ExpenseLog
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        switch horizontalSizeClass {
            
        case .compact: compactView
        default : regularView
       
        }
        
    }
    
    var compactView : some View {
        HStack(spacing: 16) {
            CategoriesImageView(category: log.categoryEnum)
            VStack(alignment: .leading,spacing: 8) {
                Text(log.name).font(.headline)
                Text(log.dateText).font(.subheadline)
               
                
            }
            Spacer()
            Text(log.amountText).font(.headline)
        }
    }
    var regularView : some View {
        HStack(spacing: 16) {
            CategoriesImageView(category: log.categoryEnum)
            Spacer()
            Text(log.name)
                .frame(minWidth: 0,maxWidth: .infinity,alignment: .leading)
            Spacer()
            Text(log.amountText)
                .frame(minWidth: 0,maxWidth: .infinity,alignment: .leading)
            Spacer()
            Text(log.dateText)
                .frame(minWidth: 0,maxWidth: .infinity,alignment: .leading)
            Spacer()
            Text(log.categoryEnum.rawValue)
                .frame(minWidth: 0,maxWidth: .infinity,alignment: .leading)
            Spacer()
            
        }
    }
    
}


//#Preview {
//    
//    VStack {
//        
//        ForEach([ExspenseLog(id: "1", name: "sushi", category: "Drink", amount: 10, currency: "USD", date: .now),ExspenseLog(id: "2", name: "Electricity", category: "Utilities", amount: 100, currency: "USD", date: .now)]) { log in
//            LogItemView(log: log)
//        }
//        
//    }
//  
//}
