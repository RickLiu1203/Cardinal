//
//  AuthViewModel.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//

import SwiftUI
import FirebaseAuth
import GoogleSignIn

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
    
    func handleGoogleSignInURL(_ url: URL) {
        GIDSignIn.sharedInstance.handle(url)
    }
}