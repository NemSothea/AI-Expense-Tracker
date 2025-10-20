//
//  FilterCategoriesView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import SwiftUI

struct CategoriesImageView: View {
    
    let category: Category
    
    var body: some View {
        Image(systemName: category.systemNameIcon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
            .padding(.all, 10)
            .foregroundColor(category.color)
            .background(category.color.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(category.color.opacity(0.3), lineWidth: 1)
            )
    }
}


//#Preview {
//
//    return CategoriesImageView(category: .utilities)
//}
