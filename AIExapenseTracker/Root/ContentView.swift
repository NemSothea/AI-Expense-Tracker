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
    
    // ⬇️ added
    var onLogout: () -> Void = {}
    
    
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
            // Home
            NavigationStack {
                AnimatedDashboardHomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Exspense
            NavigationStack {
                LogListContainerView(vm: $vm)
            }
            .tabItem {
                Label("Expenses", systemImage: "list.bullet")
            }
            .tag(1)
            
            NavigationStack {
                AIAssitantView()
            }
            .tabItem {
                Label("AI Assistant", systemImage: "waveform")
            }.tag(2)
            NavigationStack {
                EnhancedAccountView(onLogout: onLogout)
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }.tag(3)
        }
    }
    var splitView : some View {
        NavigationSplitView {
            List {
                NavigationLink(destination: AnimatedDashboardHomeView()) {
                    Label("Dashboard", systemImage: "house.fill")
                }
                
                NavigationLink(destination: LogListContainerView(vm: $vm)) { // ⬅️ Fixed this line
                    Label("Expense", systemImage: "tray")
                }
                NavigationLink(destination: AIAssitantView()) {
                    Label("AI Assistant", systemImage: "waveform")
                }
                
                NavigationLink(destination: EnhancedAccountView(onLogout: onLogout)) {
                    Label("Account", systemImage: "person.circle")
                }
            }
        } detail: {
            AnimatedDashboardHomeView()
        }
        .navigationTitle("AI Expenses Tracker")
    }
}

//#Preview {
//    ContentView()
//}
