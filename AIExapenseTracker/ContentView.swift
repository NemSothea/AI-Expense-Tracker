//
//  ContentView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 10/12/24.
//

import SwiftUI

struct ContentView: View {

    @State var vm = LogListViewModel()
    @ObservedObject private var lm = LocalizationManager.shared

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
                Label(lm.L(.home), systemImage: "bolt.house.fill")
            }.tag(0)

            NavigationStack {
                LogListContainerView(vm: $vm)
            }
            .tabItem {
                Label(lm.L(.expense), systemImage: "tray")
            }.tag(1)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label(lm.L(.profile), systemImage: "person.circle")
            }.tag(2)

//            NavigationStack {
//                loadWebView()
//            }
//            .tabItem {
//                Label("Expense", systemImage: "tray")
//            }.tag(2)
//
//            NavigationStack {
//                AIAssistantView()
//            }
//            .tabItem {
//                Label("AI Assistant", systemImage: "waveform")
//            }.tag(3)
//
//            NavigationStack {
//                ExpenseReceiptScannerView()
//            }
//            .tabItem {
//                Label("Receipt Scanner", systemImage: "eye")
//            }.tag(4)
        }
        // Propagate Battambang as the default body font for all unlabeled text
        // (Form labels, Picker rows, Buttons, Section headers, etc.)
        .environment(\.font, lm.appBody)
    }

    var splitView : some View {
        NavigationSplitView {
            List(selection: $selectedTab) {

                NavigationLink(value: 0) {
                    Label(lm.L(.home), systemImage: "bolt.house.fill")
                }

                NavigationLink(value: 1) {
                    Label(lm.L(.expense), systemImage: "tray")
                }
                NavigationLink(value: 2) {
                    Label(lm.L(.quiz), systemImage: "q.circle")
                }
                NavigationLink(value: 3) {
                    Label(lm.L(.aiAssistant), systemImage: "waveform")
                }

                NavigationLink(value: 4) {
                    Label(lm.L(.receiptScanner), systemImage: "eye")
                }
            }
            .navigationTitle(lm.L(.appName))
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
                LogListContainerView(vm: $vm)
            case 3:
                AIAssistantView()
            case 4:
                ExpenseReceiptScannerView()
            default:
                AnimatedDashboardHomeView()
            }
        }
        .environment(\.font, lm.appBody)
    }
}

//#Preview {
//    ContentView()
//}
