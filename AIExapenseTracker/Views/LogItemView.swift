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
        
        let _ = Self._printChanges()
        
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
            Text(log.amountListText).font(.headline)
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

