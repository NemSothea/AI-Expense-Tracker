//
//  FilterCategoriesView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import SwiftUI

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
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories) { category in
                        FilterButtonView(
                            category: category,
                            isSelected: self.selectedCategories.contains(category),
                            onTap: self.onTap
                        )
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 50) // ⬅️ Added fixed height for consistency
            
            if !selectedCategories.isEmpty {
                Button(role: .destructive) {
                    self.selectedCategories.removeAll()
                } label: {
                    #if os(macOS)
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Clear all filters (\(self.selectedCategories.count))")
                    }
                    #else
                    Text("Clear all filters (\(self.selectedCategories.count))")
                    #endif
                }
                .buttonStyle(.plain) // ⬅️ Important for macOS
                .padding(.bottom, 8)
            }
        }
        .padding(.vertical, 8)
        .background(Color.systemGray6) // ⬅️ Use your system color
    }
    
    func onTap(category: Category) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
}

struct FilterButtonView: View {
    var category: Category
    var isSelected: Bool
    var onTap: (Category) -> ()
    
    var body: some View {
        Button {
            self.onTap(self.category)
        } label: {
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
        }
        .buttonStyle(.plain) // ⬅️ Important for macOS
        .foregroundColor(isSelected ? .white : Color.primary)
    }
}

//#Preview {
//    
//    @Previewable @State var vm = LogListViewModel()
//    return FilterCategoriesView(selectedCategories: $vm.selectedCategories)
//}
