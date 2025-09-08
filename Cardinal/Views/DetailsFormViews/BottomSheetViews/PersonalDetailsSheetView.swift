//
//  PersonalDetailsSheetView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//


import SwiftUI
import FirebaseAuth

struct PersonalDetailsSheetView: View {
    var onAdded: (() -> Void)? = nil
    @EnvironmentObject var formViewModel: FormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var linkedIn: String = ""
    var body: some View {
        VStack(spacing: 16) {
            Text("Personal Details")
                .font(.title2)
                .fontWeight(.bold)
            
            FormFieldView(title: "First Name", text: $firstName, inputType: .text, isMandatory: true)
            FormFieldView(title: "Last Name", text: $lastName, inputType: .text, isMandatory: true)
            FormFieldView(title: "Email", text: $email, inputType: .email, isMandatory: true)
            FormFieldView(title: "LinkedIn", text: $linkedIn, inputType: .url, isMandatory: false)
            
            Button("Add Section") {
                Task {
                    let data = FormViewModel.PersonalDetailsData(firstName: firstName, lastName: lastName, email: email, linkedIn: linkedIn)
                    await MainActor.run {
                        formViewModel.personalDetails = data
                        formViewModel.addSection(.personalDetails)
                    }
                    onAdded?()
                    dismiss()
                    if let uid = Auth.auth().currentUser?.uid {
                        try? await formViewModel.savePersonalDetails(data, userId: uid)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
            Spacer()
        }
        .padding()
    }
    private var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidEmail(email)
    }
    private func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@"), trimmed.contains(".") else { return false }
        return trimmed.count >= 5
    }
}
