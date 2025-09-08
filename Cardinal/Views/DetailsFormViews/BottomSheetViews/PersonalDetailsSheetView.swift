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
    var initialData: FormViewModel.PersonalDetailsData? = nil
    var isEditing: Bool = false
    @EnvironmentObject var formViewModel: FormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var linkedIn: String = ""
    @State private var phoneNumber: String = ""
    @State private var github: String = ""
    @State private var website: String = ""
    @State private var didPrefill: Bool = false
    var body: some View {
        VStack(spacing: 16) {
            Text("Personal Details")
                .font(.title2)
                .fontWeight(.bold)
            
            ScrollView {
                VStack(spacing: 16) {
                    FormFieldView(title: "First Name", text: $firstName, inputType: .text, isMandatory: true)
                    FormFieldView(title: "Last Name", text: $lastName, inputType: .text, isMandatory: true)
                    FormFieldView(title: "Email", text: $email, inputType: .email, isMandatory: true)
                    FormFieldView(title: "Phone Number", text: $phoneNumber, inputType: .number, isMandatory: false)
                    FormFieldView(title: "LinkedIn", text: $linkedIn, inputType: .url, isMandatory: false)
                    FormFieldView(title: "GitHub", text: $github, inputType: .url, isMandatory: false)
                    FormFieldView(title: "Personal Website", text: $website, inputType: .url, isMandatory: false)
                }
            }
            
            Button(isEditing ? "Save Changes" : "Add Section") {
                Task {
                    let data = FormViewModel.PersonalDetailsData(firstName: firstName, lastName: lastName, email: email, linkedIn: linkedIn, phoneNumber: phoneNumber, github: github, website: website)
                    await MainActor.run {
                        formViewModel.personalDetails = data
                        if !isEditing {
                            formViewModel.addSection(.personalDetails)
                        }
                    }
                    if !isEditing { onAdded?() }
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
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
        .onAppear {
            if !didPrefill, let existing = initialData {
                firstName = existing.firstName
                lastName = existing.lastName
                email = existing.email
                linkedIn = existing.linkedIn
                phoneNumber = existing.phoneNumber
                github = existing.github
                website = existing.website
                didPrefill = true
            }
        }
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
