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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text("SETTINGS")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(Color("TextPrimary"))

                // Sign Out button
                Button {
                    signOut()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.body.weight(.black))
                        Text("SIGN OUT")
                            .font(.custom("MabryPro-Black", size: 18))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .foregroundColor(Color("TextPrimary"))
                }
                .buttonStyle(.plain)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.black, lineWidth: 1.5)
                )
                .background{
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.signOutButton)
                        .shadow(color: .black, radius: 0, x: 4, y: 4)
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


