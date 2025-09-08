//
//  SkillsSheetView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//


import SwiftUI

struct SkillsSheetView: View {
    var onAdded: (() -> Void)? = nil
    @EnvironmentObject var formViewModel: FormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var skillsInput = ""
    @State private var isUploading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Skills")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                FormFieldView(
                    title: "Skills",
                    text: $skillsInput,
                    inputType: .text,
                    isMandatory: true,
                    multiline: true
                )
                
                Text("Enter your skills separated by commas (e.g., Swift, iOS, Firebase, SwiftUI)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            Button(isUploading ? "Saving..." : "Add Section") {
                Task {
                    isUploading = true
                    errorMessage = nil
                    
                    do {
                        if let uid = formViewModel.currentUserId {
                            try await formViewModel.saveSkills(skillsString: skillsInput, userId: uid)
                            await MainActor.run {
                                isUploading = false
                                onAdded?()
                                dismiss()
                            }
                        } else {
                            await MainActor.run {
                                isUploading = false
                                errorMessage = "No user logged in"
                            }
                        }
                    } catch {
                        await MainActor.run {
                            isUploading = false
                            errorMessage = "Save failed: \(error.localizedDescription)"
                            print("Skills save error: \(error)")
                        }
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(skillsInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isUploading)
        }
        .padding()
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
        .onAppear {
            // Pre-fill with existing skills if editing
            if let existingSkills = formViewModel.skills?.skills {
                skillsInput = existingSkills.joined(separator: ", ")
            }
        }
    }
}
