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
        
        let _ = Self._printChanges()
        
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
    
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color {
        if isSelected {
            return category.color
        } else {
#if os(iOS)
     return colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5)
     #elseif os(macOS)
     // macOS system colors
     return colorScheme == .dark ? Color(.windowBackgroundColor) : Color(.controlBackgroundColor)
#endif
        }
    }
    
    var strokeColor: Color {
        if isSelected {
            return category.color
        } else {
            return colorScheme == .dark ? Color.gray.opacity(0.4) : Color.gray.opacity(0.5)
        }
    }
    
    var textColor: Color {
        if isSelected {
            // Ensure text is readable on the category color
            return category.color.isLight ? .black : .white
        } else {
            return .primary
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(category.rawValue.capitalized)
                .fixedSize(horizontal: true, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(strokeColor, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(backgroundColor)
                        )
                }
                .frame(height: 44)
                .onTapGesture {
                    self.onTap(self.category)
                }
                .foregroundStyle(textColor)
        }
    }
}





#Preview {
    
    @Previewable @State var vm = LogListViewModel()
    return FilterCategoriesView(selectedCategories: $vm.selectedCategories)
}
