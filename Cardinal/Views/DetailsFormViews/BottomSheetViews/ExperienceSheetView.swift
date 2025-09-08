//
//  ExperienceSheetView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//


import SwiftUI
import FirebaseAuth

struct ExperienceSheetView: View {
    var onAdded: (() -> Void)? = nil
    @EnvironmentObject var formViewModel: FormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var company: String = ""
    @State private var role: String = ""
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date()
    @State private var descriptionText: String = ""
    var body: some View {
        VStack(spacing: 16) {
            Text("Experience")
                .font(.title2)
                .fontWeight(.bold)
            FormFieldView(title: "Company", text: $company, inputType: .text, isMandatory: true)
            FormFieldView(title: "Role", text: $role, inputType: .text, isMandatory: true)
            VStack(alignment: .leading, spacing: 8) {
                Text("Start Date")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
            }
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Has End Date", isOn: $hasEndDate)
                if hasEndDate {
                    DatePicker("", selection: $endDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            FormFieldView(title: "Description", text: $descriptionText, inputType: .text, isMandatory: false, multiline: true)
            Button("Add Experience") {
                formViewModel.addExperienceLocally(company: company, role: role, startDate: startDate, endDate: hasEndDate ? endDate : nil, description: descriptionText.isEmpty ? nil : descriptionText)
                onAdded?()
                dismiss()
                if let uid = Auth.auth().currentUser?.uid {
                    Task { try? await formViewModel.saveExperience(company: company, role: role, startDate: startDate, endDate: hasEndDate ? endDate : nil, description: descriptionText.isEmpty ? nil : descriptionText, userId: uid) }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
            Spacer()
        }
        .padding()
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
    }
    private var isValid: Bool {
        !company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
