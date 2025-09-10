//
//  LandingModalView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-09.
//

import SwiftUI

struct LandingModalView: View {
    @Binding var isPresented: Bool
    var onSubmit: (() -> Void)? = nil
    @State private var tempName: String = UserDefaults.standard.string(forKey: "clipVisitorName") ?? ""
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Text("Welcome 👋")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(Color("TextPrimary"))

                Text("Enter your name to mark your visit! (Optional)")
                    .font(.system(size: 16))
                    .foregroundColor(Color("TextPrimary"))
                    .multilineTextAlignment(.leading)
            }

            HStack(spacing: 12) {
                TextField("Your Name (Leave Blank to Stay Anonymous)", text: $tempName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .foregroundColor(Color("TextPrimary"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background{
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("BackgroundPrimary"))
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 1.5)
                    )
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .textContentType(.name)
                    .submitLabel(.go)
                    .focused($nameFocused)
                    .onSubmit {
                        submitName()
                    }

                Button {
                    submitName()
                } label: {
                    Text("GO")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color("TextPrimary"))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                .background{
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("BackgroundPrimary"))
                        .shadow(color: .black, radius: 0, x: 2, y: 2)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 1.5)
                )
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding(20)
        .background{
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("BackgroundPrimary"))
                .shadow(color: .black, radius: 0, x: 4, y: 4)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: 2)
        )
        .padding(.horizontal, 16)
    }
    
    private func submitName() {
        // 1) Ask keyboard to resign
        nameFocused = false
        let trimmedName = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            UserDefaults.standard.set(trimmedName, forKey: "clipVisitorName")
        }
        // 2) Defer dismiss until next runloop to avoid RTI snapshot warnings
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            isPresented = false
            onSubmit?()
        }
    }
}

