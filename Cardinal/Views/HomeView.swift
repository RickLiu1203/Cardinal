//
//  HomeView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    let user: User
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Welcome to Cardinal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Signed in as")
                    .foregroundColor(.secondary)
                Text(user.email ?? user.displayName ?? user.uid)
                    .font(.headline)
            }
            
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("5")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Cards Created")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("127")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Total Views")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                }
                
                Button(role: .destructive) {
                    signOut()
                } label: {
                    Text("Sign out")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

// MARK: - Sign Out
private extension HomeView {
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
