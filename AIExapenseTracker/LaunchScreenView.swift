//
//  LaunchScreenView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 3/12/25.
//


import SwiftUI

struct LaunchScreenView: View {
    
    @State private var isActive = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.blue, Color.random()],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // App Logo/Icon
                    Image("launchicon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120,height: 120)
                        .clipShape(Circle())
                        
                    
                    // App Name
                    Text("AI Expense Tracker")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(opacity)
                    
                    // Tagline
                    Text("Smart Finance Management")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(opacity)
                    
                    // Loading indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                        .padding(.top, 30)
                }
                .padding()
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    scale = 1.0
                }
                
                withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                    opacity = 1.0
                }
                
                // Simulate loading time
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isActive = true
                    }
                }
            }
        }
    }
}

//#Preview {
//    LaunchScreenView()
//}
