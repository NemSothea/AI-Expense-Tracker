//
//  SelectSorthOrderView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import SwiftUI

struct SelectSortOrderView: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject private var lm = LocalizationManager.shared

    @Binding var sortType: SortType
    @Binding var sortOrder: SortOrder
   
    
    
    private let sortTypes = SortType.allCases
    private let sortOrders = SortOrder.allCases
    
    var body: some View {
        HStack {
#if !os(macOS)
            Text(lm.L(.sortBy))
#endif
            Picker(selection: $sortType, label: Text(lm.L(.sortBy))) {
                ForEach(sortTypes) { type in
                
                    if horizontalSizeClass == .compact {
                        Image(systemName: type.systemNameIcon).tag(type)
                    }else {
                        Text(type.rawValue.capitalized)
                            .tag(type)
                        
                    }
                    
                }
            }.pickerStyle(SegmentedPickerStyle())
            
#if !os(macOS)
            Text(lm.L(.orderBy))
#endif
            Picker(selection: $sortOrder, label: Text(lm.L(.orderBy))) {
                ForEach(sortOrders) { order in
                
                    if horizontalSizeClass == .compact {
                        Image(systemName: order == .ascending ? "arrow.up" : "arrow.down").tag(order)
                    }else {
                        Text(order.rawValue.capitalized)
                            .tag(order)
                        
                    }
                    
                }
            }.pickerStyle(SegmentedPickerStyle())
            
            
        }
        .padding()
        .frame(height: 64)
    }
   
}

#Preview {
    @Previewable @State var vm = LogListViewModel()
    SelectSortOrderView( sortType: $vm.sortType, sortOrder: $vm.sortOrder)
}
