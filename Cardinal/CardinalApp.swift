//
//  CardinalApp.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn
import CoreText

@main
struct CardinalApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var formViewModel = FormViewModel()
    
    init() {
        FirebaseApp.configure()
        UIFont.registerCustomFonts()
        
        // Debug: List available fonts
        print("🔍 Available font families:")
        for family in UIFont.familyNames.sorted() {
            print("Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  - \(name)")
            }
        }
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
            .onChange(of: authViewModel.currentUser?.uid) { _, newUid in
                // Clear stale data when the user changes (logout/login or account switch)
                formViewModel.clearUserData()
                if let uid = newUid {
                    Task { await formViewModel.fetchPersonalDetails(userId: uid) }
                }
            }
        }
    }
}
