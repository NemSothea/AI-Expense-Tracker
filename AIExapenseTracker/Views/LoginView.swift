//
//  LoginView.swift
//  AIExapenseTracker
//
//  Created by sothea007 on 3/9/25.
//

import SwiftUI
import Alamofire

struct LoginView: View {
    var onCancel: () -> Void
    var onSuccess: () -> Void
    
    @StateObject private var viewModel = LoginViewModel()
    
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Title
            titleSection
            
            // Email Field
            emailField
            
            // Password Field
            passwordField
            
            // Error Message
            errorMessage
            
            // Sign In Button
            signInButton
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    // MARK: - View Components
    private var titleSection: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.white)
                    .font(.system(size: 40))
                    .padding()
            }
            .background(Color.blue)
            .cornerRadius(7)
            .frame(width: 100, height: 100)
            
            VStack(alignment: .center) {
                Text("AI Expense Tracker")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Smart Financial Tracking")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.bottom, 40)
    }
    
    private var emailField: some View {
        HStack {
            Image(systemName: "envelope")
                .foregroundColor(.gray)
            TextField("Enter your email", text: $viewModel.email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var passwordField: some View {
        HStack {
            Image(systemName: "lock")
                .foregroundColor(.gray)
            if isPasswordVisible {
                TextField("Enter your password", text: $viewModel.password)
                    .textContentType(.password)
            } else {
                SecureField("Enter your password", text: $viewModel.password)
                    .textContentType(.password)
            }
            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    @ViewBuilder
    private var errorMessage: some View {
        if let error = viewModel.error {
            Text(error)
                .foregroundColor(.red)
                .font(.footnote)
                .multilineTextAlignment(.center)
        }
    }
    
    private var signInButton: some View {
        Button {
            Task {
                await signIn()
            }
        } label: {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Text("SIGN IN")
                    .font(.title2)
                    .frame(maxWidth: .infinity, maxHeight: 20)
                    .padding()
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty || viewModel.isLoading)
        .padding(.top, 10)
    }
    
    // MARK: - Methods
    private func signIn() async {
        let success = await viewModel.login()
        if success {
            onSuccess()
        }
    }
}

//#Preview {
//    LoginView(
//        onCancel: {},
//        onSuccess: {}
//    )
//}
