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
    
    // Add selection state for macOS
    @State private var selectedTab: Int? = 0 // Default to Home
    
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
                Label("Expense", systemImage: "tray")
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
            List(selection: $selectedTab) {
                
                NavigationLink(value: 0) {
                    Label("Home", systemImage: "bolt.house.fill")
                }
                
                NavigationLink(value: 1) {
                    Label("Expense", systemImage: "tray")
                }
                
                NavigationLink(value: 2) {
                    Label("AI Assistant", systemImage: "waveform")
                }
                
                NavigationLink(value: 3) {
                    Label("Receipt Scanner", systemImage: "eye")
                }
            }
            .navigationTitle("AI Expense Tracker")
            .onAppear {
                // Ensure Home is selected by default on macOS
                if selectedTab == nil {
                    selectedTab = 0
                }
            }
            
        } detail: {
            switch selectedTab {
            case 0:
                AnimatedDashboardHomeView()
            case 1:
                LogListContainerView(vm: $vm)
            case 2:
                AIAssistantView()
            case 3:
                ExpenseReceiptScannerView()
            default:
                AnimatedDashboardHomeView()
            }
        }
    }
}

//#Preview {
//    ContentView()
//}
