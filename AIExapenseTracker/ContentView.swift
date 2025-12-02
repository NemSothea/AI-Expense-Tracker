//
//  ContentView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import SwiftUI

struct ContentView: View {
    
    @State var vm = LogListViewModel()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    
    var body: some View {
#if os(macOS)
        splitView
#elseif os(visionOS)
        tapView
#else
        switch horizontalSizeClass {
        case .compact: tapView
        default : splitView
            
        }
#endif
    }
    
    var tapView : some View {
        TabView {
            NavigationStack {
                AnimatedDashboardHomeView()
            }
            .tabItem {
                    Label("Home", systemImage: "bolt.house.fill")
            }.tag(0)
            
            NavigationStack {
                LogListContainerView(vm: $vm)
            }
            .tabItem {
                Label("Exspense", systemImage: "tray")
            }.tag(1)
            
            NavigationStack {
                AIAssistantView()
            }
            .tabItem {
                Label("AI Assistant", systemImage: "waveform")
            }.tag(2)
            
            NavigationStack {
                ExpenseReceiptScannerView()
            }
            .tabItem {
                Label("Receipt Scanner", systemImage: "eye")
            }.tag(3)
           
        }
    }
    var splitView : some View {
        NavigationSplitView {
            List {
                NavigationLink(destination: LogListView(vm: $vm)) {
                    Label("Exspense", systemImage: "tray")
                }
                NavigationLink(destination: AIAssistantView()) {
                    Label("AI Assistant", systemImage: "waveform")
                }
                
               
            }
            
            
        } detail : {
            LogListContainerView(vm: $vm)
        }
        .navigationTitle("AI Expenses Tracker")
    }
}

//#Preview {
//    ContentView()
//}
