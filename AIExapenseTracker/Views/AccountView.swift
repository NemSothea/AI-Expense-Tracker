//
//  AccountView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 25/9/25.
//
import SwiftUI

// MARK: - Simple Account screen with Logout
struct AccountView: View {
    
    var onLogout: () -> Void
    var body: some View {
        Form {
            Section("Account") {
                // put user info here if you have it
                Button(role: .destructive) {
                    onLogout()
                } label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Account")
    }
}
