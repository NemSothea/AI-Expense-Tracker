//
//  FilterCategoriesView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//
import FirebaseFirestore
import SwiftUI

struct LogListView: View {
    
    @Binding var vm : LogListViewModel
    
    @FirestoreQuery(collectionPath: "logs",predicates: [.order(by: SortType.date.rawValue, descending: true)])
    
    private var logs : [ExpenseLog]
    
    var body: some View {
    
        listView
            .sheet(item: $vm.logToEdit, onDismiss: {
                vm.logToEdit = nil
            }) { log in
                LogFormView(vm:.init(logToEdit: log))
            }
            .overlay {
                if logs.isEmpty {
                    Text("No expenses data\n Please add expenses using the add button")
                        .multilineTextAlignment(.center)
                        .font(.headline)
                        .padding(.horizontal)
                }
            }
            .onChange(of: vm.sortType) {
                updateFireStoreQuery()
            }
            .onChange(of: vm.sortOrder) {
                updateFireStoreQuery()
            }
            .onChange(of: vm.selectedCategories) {
                updateFireStoreQuery()
            }
    }
    
    var listView : some View {
#if os(iOS)
        List {
            ForEach(logs) { log in
                LogItemView(log: log)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        vm.logToEdit = log
                    }
                    .padding(.vertical,4)
                
            }
            .onDelete(perform: self.onDelete)
        }
        .listStyle(.plain)
#else
        ZStack {
            ScrollView {
                ForEach(logs) { log in
                    VStack {
                        LogItemView(log: log)
                        Divider()
                    }
                    .frame(minWidth: 0, maxHeight: .infinity,alignment: .leading)
                    .contentShape(Rectangle())
                    .padding(.horizontal)
                    .onTapGesture {
                        self.vm.logToEdit = log
                    }
                    .contextMenu {
                        Button("Edit") {
                            self.vm.logToEdit = log
                        }
                        Button("Delete") {
                            vm.db.delete(log: log)
                        }
                    }
                
                }
                .contentMargins(.vertical,8,for: .scrollContent)
        }
    }
#endif
    }
    
    private func onDelete(with indexSet: IndexSet) {
        indexSet.forEach {  index in
            let log = logs[index]
            vm.db.delete(log: log)
        }
    }
    func updateFireStoreQuery() {
        $logs.predicates = vm.predicates
    }
    
    
}


#Preview {
    @Previewable @State var vm = LogListViewModel()
    return LogListView(vm: $vm)
  
}
