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
    
    @AppStorage("didSeeIntro") private var didSeeIntro          = false
    @AppStorage("isAuthenticated") private var isAuthenticated  = false
    
    @State private var route: AppRoute = .intro
    
    @State private var didStart = false
    
    var body: some View {
        currentScene
            .onAppear {
                // Decide initial route on app launch
                if isAuthenticated {
                    route = .content
                } else if didSeeIntro {
                    route = .login
                } else {
                    route = .intro
                }
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
                onCancel: { route = .intro },
                onSuccess: {
                    isAuthenticated = true
                    route = .content
                }
            )
            
        case .content:
            ContentView(onLogout: {
                isAuthenticated = false
                route = .login
            })
        }
    }
}

