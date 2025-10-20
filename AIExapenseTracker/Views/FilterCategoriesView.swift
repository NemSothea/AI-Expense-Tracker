//
//  FilterCategoriesView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import SwiftUI

struct FilterCategoriesView: View {
    
    @Binding var selectedCategories: Set<Category>
    private let categories = Category.allCases
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack(spacing:8) {
                    
                    ForEach(categories) { category in
                        FilterButtonView(category: category, isSelected: self.selectedCategories.contains(category), onTap: self.onTap)
                    }
                }
                .padding(.horizontal)
            }
            if selectedCategories.count > 0 {
                Button(role: .destructive) {
                    
                    self.selectedCategories.removeAll()
                    
                } label: {
                    
                    Text("Clear all filter selection \(self.selectedCategories.count)")
                }

            }
        }
    }
    
    func onTap(category: Category) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        }else {
            selectedCategories.insert(category)
        }
    }
    
}


struct FilterButtonView: View {
    var category: Category
    var isSelected: Bool
    var onTap: (Category) -> ()
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: category.systemNameIcon)
                .font(.caption)
                .foregroundColor(isSelected ? .white : category.color)
            
            Text(category.rawValue.capitalized)
                .font(.caption)
                .fixedSize(horizontal: true, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? category.color : Color.gray, lineWidth: 1)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundColor(isSelected ? category.color : Color.clear)
                }
        }
        .frame(height: 32)
        .onTapGesture {
            self.onTap(self.category)
        }
        .foregroundColor(isSelected ? .white : Color.primary)
    }
}


//#Preview {
//    
//    @Previewable @State var vm = LogListViewModel()
//    return FilterCategoriesView(selectedCategories: $vm.selectedCategories)
//}
