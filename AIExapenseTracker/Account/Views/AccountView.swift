//
//  AccountView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 25/9/25.
//
import SwiftUI

struct EnhancedAccountView: View {
    var onLogout: () -> Void
    
    @State private var user: User?
    @State private var showingLogoutConfirmation = false
    
    // Get app version from bundle
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "Version \(version)"
    }
    
    
    var body: some View {
        List {
            // Header Section
            Section {
                HStack(spacing: 16) {
                    // User Avatar
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 60)
                        
                        Text(userInitials)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user?.name ?? "Loading...")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(user?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let role = user?.role {
                            Text(role.replacingOccurrences(of: "ROLE_", with: ""))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            
          
            // Support & Legal Section
            Section("Support & Legal") {
                Link(destination: URL(string: "http://localhost:5173/terms-of-service")!) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        
                        Text("Terms of Service")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.forward.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Link(destination: URL(string: "http://localhost:5173/privacy-policy")!) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                            .frame(width: 30)
                        
                        Text("Privacy Policy")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.forward.square")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
               
            }
            
            // Actions Section
            Section {
                Button(role: .destructive) {
                    showingLogoutConfirmation = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        Spacer()
                    }
                }
            }
            
            // Footer Section
            Section {
                VStack(spacing: 5) {
                   
                    
                    Text(appVersion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("© 2025 AI Expense Tracker System. All Rights Reserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Account")
        .confirmationDialog(
            "Are you sure you want to logout?",
            isPresented: $showingLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Logout", role: .destructive) {
                onLogout()
            }
            Button("Cancel", role: .cancel) {
                showingLogoutConfirmation = false
            }
        }
        .task {
            await loadUserProfile()
        }
    }
    
    private var userInitials: String {
        guard let name = user?.name else { return "?" }
        let components = name.components(separatedBy: " ")
        if components.count >= 2, let first = components.first?.first, let last = components.last?.first {
            return "\(first)\(last)".uppercased()
        } else if let first = name.first {
            return "\(first)".uppercased()
        }
        return "?"
    }
    
    @MainActor
    private func loadUserProfile() async {
        user = AuthManager.shared.currentUser
    }
}

//#Preview {
//    NavigationStack {
//        EnhancedAccountView(onLogout: {})
//    }
//}
