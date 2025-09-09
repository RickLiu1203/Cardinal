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
    var initialData: FormViewModel.ExperienceData? = nil
    var isEditing: Bool = false
    @EnvironmentObject var formViewModel: FormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var company: String = ""
    @State private var role: String = ""
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date()
    @State private var descriptionText: String = ""
    @State private var didPrefill: Bool = false
    var body: some View {
        VStack(spacing: 16) {
            Text(isEditing ? "Edit Experience" : "Experience")
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
            Button(isEditing ? "Save Changes" : "Add Experience") {
                if isEditing, let id = initialData?.id {
                    Task {
                        await formViewModel.updateExperience(id: id, company: company, role: role, startDate: startDate, endDate: hasEndDate ? endDate : nil, description: descriptionText.isEmpty ? nil : descriptionText)
                        dismiss()
                    }
                } else {
                    formViewModel.addExperienceLocally(company: company, role: role, startDate: startDate, endDate: hasEndDate ? endDate : nil, description: descriptionText.isEmpty ? nil : descriptionText)
                    onAdded?()
                    dismiss()
                    if let uid = Auth.auth().currentUser?.uid {
                        Task { try? await formViewModel.saveExperience(company: company, role: role, startDate: startDate, endDate: hasEndDate ? endDate : nil, description: descriptionText.isEmpty ? nil : descriptionText, userId: uid) }
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
            if !didPrefill, let initial = initialData {
                company = initial.company
                role = initial.role
                // Parse dates from stored strings
                let df = DateFormatter()
                df.dateStyle = .medium
                if let parsedStart = df.date(from: initial.startDateString) {
                    startDate = parsedStart
                }
                if let endStr = initial.endDateString, let parsedEnd = df.date(from: endStr) {
                    hasEndDate = true
                    endDate = parsedEnd
                } else {
                    hasEndDate = false
                }
                descriptionText = initial.description ?? ""
                didPrefill = true
            }
        }
    }
    private var isValid: Bool {
        !company.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
