//
//  CardinalApp.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct CardinalApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var formViewModel = FormViewModel()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let user = authViewModel.currentUser {
                    RootTabView(user: user)
                        .environmentObject(formViewModel)
                } else {
                    AuthView()
                }
            }
            .onOpenURL { url in
                authViewModel.handleGoogleSignInURL(url)
            }
        }
    }
}
