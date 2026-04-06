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
    @Environment(AppSettings.self) private var settings

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // Add selection state for macOS
    @State private var selectedTab: Int? = 0  // split view (macOS / iPad)
    @State private var mobileTab: Int = 0     // tab view (iPhone)

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
        TabView(selection: $mobileTab) {
            NavigationStack {
                AnimatedDashboardHomeView(logType: settings.selectedLogType)
            }
            .tabItem {
                Label(lm.L(.home), systemImage: "bolt.house.fill")
            }.tag(0)

            NavigationStack {
                LogListContainerView(vm: $vm, logType: settings.selectedLogType)
            }
            .tabItem {
                Label(lm.L(.expense), systemImage: "tray")
            }.tag(1)
            
            NavigationStack {
                VisionReceiptScannerView()
            }
            .tabItem {
                Label(lm.L(.receiptScanner), systemImage: "doc.viewfinder")
            }.tag(2)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label(lm.L(.profile), systemImage: "person.circle")
            }.tag(3)

           
        }
        // Propagate Battambang as the default body font for all unlabeled text
        // (Form labels, Picker rows, Buttons, Section headers, etc.)
        .environment(\.font, lm.appBody)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToExpenseList)) { _ in
            mobileTab = 1
        }
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
                    Label(lm.L(.receiptScanner), systemImage: "doc.viewfinder")
                }
                
                NavigationLink(value: 3) {
                    Label(lm.L(.profile), systemImage: "person.circle")
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
                AnimatedDashboardHomeView(logType: settings.selectedLogType)
            case 1:
                LogListContainerView(vm: $vm, logType: settings.selectedLogType)
            case 2:
                VisionReceiptScannerView()
            case 3:
                ProfileView()
            default:
                AnimatedDashboardHomeView(logType: settings.selectedLogType)
            }
        }
        .environment(\.font, lm.appBody)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToExpenseList)) { _ in
            selectedTab = 1
        }
    }
}

//#Preview {
//    ContentView()
//}
