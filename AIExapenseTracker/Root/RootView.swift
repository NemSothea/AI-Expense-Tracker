//
//  AppRoute.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 25/9/25.
//

import SwiftUI

// MARK: - App Route
enum AppRoute {
    case intro
    case login
    case content
}

// MARK: - Root
struct RootView: View {
    @AppStorage("didSeeIntro") private var didSeeIntro = false
    
    // Use AuthManager instead of @AppStorage for authentication state
    @EnvironmentObject private var authManager: AuthManager
    @State private var route: AppRoute = .intro
    @State private var didStart = false
    @State private var showingSessionExpiredAlert = false
    
    var body: some View {
        currentScene
            .onAppear {
                // Decide initial route on app launch based on AuthManager
                if authManager.isLoggedIn {
                    route = .content
                } else if didSeeIntro {
                    route = .login
                } else {
                    route = .intro
                }
            }
            .onChange(of: authManager.isLoggedIn) { oldValue, newValue in
                // Handle logout from AuthManager (e.g., session expiration)
                if !newValue && oldValue {
                    // User was logged in but now is logged out
                    route = .login
                    showingSessionExpiredAlert = true
                } else if newValue && !oldValue {
                    // User logged in successfully
                    route = .content
                }
            }
            .alert("Session Expired", isPresented: $showingSessionExpiredAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your session has expired. Please log in again.")
            }
            .animation(.default, value: route)
    }
    
    // MARK: - Scene Router
    @ViewBuilder
    private var currentScene: some View {
        switch route {
        case .intro:
            IntroductionView(
                onLoginTapped: {
                    didSeeIntro = true
                    route = .login
                }
            )
            
        case .login:
            LoginView(
                onCancel: {
                    route = .intro
                },
                onSuccess: {
                    // AuthManager already handles login state internally
                    route = .content
                }
            )
            
        case .content:
            ContentView(onLogout: {
                // Use AuthManager's logout method
                authManager.logout()
                route = .login
            })
            .environmentObject(authManager) // Pass authManager to content hierarchy
        }
    }
}
