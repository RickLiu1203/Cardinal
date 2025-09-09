//
//  AuthView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//

import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var isSignUpMode: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text(isSignUpMode ? "Create Account" : "Sign In")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                        
                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .font(.footnote)
                        }
                    }
                    
                    VStack(spacing: 12) {
                        Button {
                            if isSignUpMode {
                                signUp()
                            } else {
                                signIn()
                            }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Text(isLoading ? "Please wait..." : (isSignUpMode ? "Create Account" : "Sign In"))
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        
                        Button {
                            isSignUpMode.toggle()
                            errorMessage = nil
                        } label: {
                            Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(.footnote)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Authentication Methods
private extension AuthView {
    func signIn() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authViewModel.signIn(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signUp() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authViewModel.signUp(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    AuthView()
}