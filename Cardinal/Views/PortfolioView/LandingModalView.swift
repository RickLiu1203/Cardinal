//
//  LandingModalView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-09.
//

import SwiftUI

struct LandingModalView: View {
    @Binding var isPresented: Bool
    let ownerId: String
    var onSubmit: (() -> Void)? = nil
    @State private var tempName: String = ""
    @FocusState private var nameFocused: Bool
    @State private var isButtonPressed: Bool = false
    
    init(isPresented: Binding<Bool>, ownerId: String, onSubmit: (() -> Void)? = nil) {
        self._isPresented = isPresented
        self.ownerId = ownerId
        self.onSubmit = onSubmit
        // Initialize tempName with portfolio-specific stored name
        let portfolioSpecificKey = "clipVisitorName_\(ownerId)"
        self._tempName = State(initialValue: UserDefaults.standard.string(forKey: portfolioSpecificKey) ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("WELCOME TO MY PORTFOLIO")
                    .font(.custom("MabryPro-Black", size: 28))
                    .foregroundColor(Color("TextPrimary"))

                Text("Optionally enter your name to mark your visit!")
                    .font(.custom("MabryPro-Regular", size: 18))
                    .foregroundColor(Color("TextPrimary"))
                    .multilineTextAlignment(.leading)
            }

            VStack(alignment: .leading, spacing: 20) {
                ZStack(alignment: .leading) {
                    if tempName.isEmpty {
                        Text("Your Name (Optional)")
                            .font(.custom("MabryPro-Italic", size: 18))
                            .foregroundColor(Color("TextPrimary"))
                            .opacity(0.6)
                            .padding(.horizontal, 16)
                            .frame(height: 48)
                    }
                    TextField("", text: $tempName)
                        .textFieldStyle(.plain)
                        .font(.custom("MabryPro-Italic", size: 18))
                        .foregroundColor(Color("TextPrimary"))
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .textContentType(.name)
                        .submitLabel(.go)
                        .focused($nameFocused)
                        .onSubmit {
                            submitName()
                        }
                }
                .background{
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color("BackgroundPrimary"))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 1.5)
                )

                Text("GO")
                    .font(.custom("MabryPro-BlackItalic", size: 18))
                    .foregroundColor(Color("TextPrimary"))
                    .textCase(.uppercase)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background{
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.homeAccent)
                            .shadow(color: isButtonPressed ? .clear : .black, radius: 0, x: isButtonPressed ? 0 : 4, y: isButtonPressed ? 0 : 4)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 1.5)
                    )
                    .offset(x: isButtonPressed ? 4 : 0, y: isButtonPressed ? 4 : 0)
                    .animation(.easeInOut(duration: 0.1), value: isButtonPressed)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.05)) {
                            isButtonPressed = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.05)) {
                                isButtonPressed = false
                            }
                            
                            submitName()
                        }
                    }
            }
        }
        .padding(.horizontal, 16)
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func submitName() {
        // 1) Ask keyboard to resign
        nameFocused = false
        let trimmedName = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
        let portfolioSpecificKey = "clipVisitorName_\(ownerId)"
        
        if !trimmedName.isEmpty {
            UserDefaults.standard.set(trimmedName, forKey: portfolioSpecificKey)
        }
        // 2) Defer dismiss until next runloop to avoid RTI snapshot warnings
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            isPresented = false
            onSubmit?()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

