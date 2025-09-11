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
                Spacer()
                VStack(alignment: .leading, spacing: 24) {
                    Text("LOG IN TO CARDINAL")
                        .font(.custom("MabryPro-Black", size: 28))
                        .foregroundColor(Color("TextPrimary"))

                    VStack(spacing: 12) {
                        ZStack(alignment: .leading) {
                            if email.isEmpty {
                                Text("Email")
                                    .font(.custom("MabryPro-Italic", size: 18))
                                    .foregroundColor(Color("TextPrimary"))
                                    .opacity(0.6)
                                    .padding(.horizontal, 16)
                                    .frame(height: 48)
                            }
                            TextField("", text: $email)
                                .textFieldStyle(.plain)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.custom("MabryPro-Italic", size: 18))
                                .foregroundColor(Color("TextPrimary"))
                                .padding(.horizontal, 16)
                                .frame(height: 48)
                        }
                        .background{
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("BackgroundPrimary"))
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 1.5)
                        )

                        ZStack(alignment: .leading) {
                            if password.isEmpty {
                                Text("Password")
                                    .font(.custom("MabryPro-Italic", size: 18))
                                    .foregroundColor(Color("TextPrimary"))
                                    .opacity(0.6)
                                    .padding(.horizontal, 16)
                                    .frame(height: 48)
                            }
                            SecureField("", text: $password)
                                .textFieldStyle(.plain)
                                .font(.custom("MabryPro-Italic", size: 18))
                                .foregroundColor(Color("TextPrimary"))
                                .padding(.horizontal, 16)
                                .frame(height: 48)
                        }
                        .background{
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("BackgroundPrimary"))
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 1.5)
                        )

                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.leading)
                                .font(.custom("MabryPro-Regular", size: 14))
                        }
                    }

                    Button {
                        signIn()
                    } label: {
                        HStack {
                            Text("LOG IN")
                                .font(.custom("MabryPro-BlackItalic", size: 18))
                                .foregroundColor(Color("TextPrimary"))
                                .textCase(.uppercase)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .background{
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.homeAccent)
                            .shadow(color: .black, radius: 0, x: 4, y: 4)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 1.5)
                    )

                    // NOTE: Temporarily disabling Sign Up access
                    // Button {
                    //     isSignUpMode.toggle()
                    //     errorMessage = nil
                    // } label: {
                    //     Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    //         .font(.footnote)
                    // }
                }
                Spacer()
            }
            .padding()
            .background(Color("BackgroundPrimary"))
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
}

// MARK: - Authentication Methods
private extension AuthView {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
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
