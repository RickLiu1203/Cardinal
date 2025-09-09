//
//  AuthViewModel.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//

import SwiftUI
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var currentUser: User? = Auth.auth().currentUser
    
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
            }
        }
    }
    
    deinit {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func signUp(email: String, password: String) async throws {
        _ = try await Auth.auth().createUser(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
}