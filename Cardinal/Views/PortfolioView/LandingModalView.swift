//
//  LandingModalView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-09.
//

import SwiftUI

struct LandingModalView: View {
    @Binding var isPresented: Bool
    @State private var tempName: String = UserDefaults.standard.string(forKey: "clipVisitorName") ?? ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome 👋")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Optionally enter your name so interactions can be tagged in the log.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            TextField("Your name (optional)", text: $tempName)
                .textFieldStyle(.roundedBorder)

            Button {
                UserDefaults.standard.set(tempName.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "clipVisitorName")
                isPresented = false
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)

            Button {
                tempName = ""
                UserDefaults.standard.removeObject(forKey: "clipVisitorName")
                isPresented = false
            } label: {
                Text("Skip")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .presentationDetents([.medium])
    }
}

