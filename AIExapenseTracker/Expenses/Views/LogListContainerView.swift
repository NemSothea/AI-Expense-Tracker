//
//  LogListContainerView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 16/12/24.
//

import SwiftUI


struct LogListContainerView: View {
    @Binding var vm: LogListViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            FilterCategoriesView(selectedCategories: $vm.selectedCategories)
            Divider()
            SelectSortOrderView(sortType: $vm.sortType, sortOrder: $vm.sortOrder)
            Divider()
            LogListView(vm: $vm)
        }
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .primaryAction) {
                Button {
                    vm.isLogFormPresented = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Expense")
                    }
                }
            }
            #else
            ToolbarItem {
                Button {
                    vm.isLogFormPresented = true
                } label: {
                    Text("Add")
                }
            }
            #endif
        }
        .sheet(isPresented: $vm.isLogFormPresented) {
            LogFormView(vm: .init(logListVM: vm))
        }
        
        #if !os(macOS)
        .navigationBarTitle("AI Expense Tracker", displayMode: .inline)
        #else
        .navigationTitle("AI Expense Tracker")
        #endif
    }
}

