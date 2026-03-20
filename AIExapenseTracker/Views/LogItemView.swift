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
            VStack(alignment: .leading, spacing: 8) {
                Text(log.name).appFont(.headline)
                Text(log.dateText).appFont(.subheadline)
            }
            Spacer()
            Text(log.amountListText).appFont(.headline)
        }
    }

    var regularView : some View {
        HStack(spacing: 16) {
            CategoriesImageView(category: log.categoryEnum)
            Spacer()
            Text(log.name)
                .appFont(.subheadline)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Spacer()
            Text(log.amountListText)
                .appFont(.subheadline)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Spacer()
            Text(log.dateText)
                .appFont(.subheadline)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Spacer()
            Text(log.categoryEnum.localizedName)
                .appFont(.subheadline)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Spacer()
        }
    }
    
}

