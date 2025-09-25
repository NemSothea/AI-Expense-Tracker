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
            NavigationStack {
                LogListContainerView(vm: $vm)
            }
            .tabItem {
                Label("Exspense", systemImage: "tray")
            }.tag(0)
            
            NavigationStack {
                AIAssitantView()
            }
            .tabItem {
                Label("AI Assistant", systemImage: "waveform")
            }.tag(1)
            NavigationStack {
                AccountView(onLogout: onLogout)
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle")
            }.tag(2)
        }
    }
    var splitView : some View {
        NavigationSplitView {
            List {
                NavigationLink(destination: LogListView(vm: $vm)) {
                    Label("Exspense", systemImage: "tray")
                }
                NavigationLink(destination: AIAssitantView()) {
                    Label("AI Assistant", systemImage: "waveform")
                }
                
                NavigationLink(destination:  AccountView(onLogout: onLogout)) {
                    Label("Account", systemImage: "person.circle")
                }
            }
            
            
        } detail : {
            LogListContainerView(vm: $vm)
        }
        .navigationTitle("AI Expenses Tracker")
    }
}

#Preview {
    ContentView()
}
