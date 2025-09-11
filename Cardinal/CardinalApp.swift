//
//  CardinalApp.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//

import SwiftUI
import FirebaseCore
import CoreText

@main
struct CardinalApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var formViewModel = FormViewModel()
    @State private var showingSplash = true
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if showingSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingSplash = false
                            }
                        }
                    }
            } else {
                Group {
                    if let user = authViewModel.currentUser {
                        RootTabView(user: user)
                            .environmentObject(formViewModel)
                    } else {
                        AuthView()
                    }
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
}

// MARK: - Splash Screen
struct SplashView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            
            Image("CardinalLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BackgroundPrimary"))
    }
}
