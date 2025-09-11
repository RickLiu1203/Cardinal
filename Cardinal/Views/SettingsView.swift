//
//  SettingsView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-10.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var formViewModel: FormViewModel
    @State private var errorMessage: String?
    @State private var isSignOutButtonPressed = false
    @State private var tapCount = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title (tap 7 times to reset App Clip data)
                Text("SETTINGS")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(Color("TextPrimary"))
                    .onTapGesture {
                        tapCount += 1
                        if tapCount >= 7 {
                            // Reset App Clip data after 7 taps on settings header
                            print("🧹 DEBUG: 7 taps on SETTINGS - clearing App Clip device ID and data")
                            // Clear analytics data (device ID, visitor names, etc.)
                            AnalyticsManager.shared.clearAllStoredData()
                            tapCount = 0 // Reset counter
                        }
                    }
                
                // Show tap count when getting close to reset (debug info)
                if tapCount > 4 {
                    Text("App Clip Reset: \(7 - tapCount) more taps")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .opacity(0.7)
                }

                // Sign Out button
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.body.weight(.black))
                    Text("SIGN OUT")
                        .font(.custom("MabryPro-Black", size: 18))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .foregroundColor(Color("TextPrimary"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.black, lineWidth: 1.5)
                )
                .background{
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.signOutButton)
                        .shadow(color: isSignOutButtonPressed ? .clear : .black, radius: 0, x: isSignOutButtonPressed ? 0 : 4, y: isSignOutButtonPressed ? 0 : 4)
                }
                .offset(x: isSignOutButtonPressed ? 4 : 0, y: isSignOutButtonPressed ? 4 : 0)
                .animation(.easeInOut(duration: 0.1), value: isSignOutButtonPressed)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.05)) {
                        isSignOutButtonPressed = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.05)) {
                            isSignOutButtonPressed = false
                        }
                        
                        signOut()
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .padding(.top, 16)
        }
        .background(Color("BackgroundPrimary"))
        .safeAreaInset(edge: .top) { Color.clear.frame(height: 0) }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
    }
}

private extension SettingsView {
    func signOut() {
        do {
            formViewModel.resetSectionOrderFlag()
            formViewModel.clearUserData()
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(FormViewModel())
}


