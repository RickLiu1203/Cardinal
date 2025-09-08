//
//  ProjectSheetView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//


import SwiftUI

struct ProjectSheetView: View {
    var onAdded: (() -> Void)? = nil
    @EnvironmentObject var formViewModel: FormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var toolsInput = ""
    @State private var link = ""
    @State private var isUploading = false
    @State private var errorMessage: String?
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Project")
                .font(.title2)
                .fontWeight(.bold)
            
            ScrollView {
                VStack(spacing: 16) {
                    FormFieldView(
                        title: "Project Title",
                        text: $title,
                        inputType: .text,
                        isMandatory: true
                    )
                    
                    FormFieldView(
                        title: "Description",
                        text: $description,
                        inputType: .text,
                        isMandatory: false,
                        multiline: true
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        FormFieldView(
                            title: "Tools Used",
                            text: $toolsInput,
                            inputType: .text,
                            isMandatory: false,
                            multiline: true
                        )
                        
                        Text("Enter tools separated by commas (e.g., Swift, Firebase, Core Data)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    FormFieldView(
                        title: "Project Link",
                        text: $link,
                        inputType: .url,
                        isMandatory: false
                    )
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            Button(isUploading ? "Saving..." : "Add Project") {
                Task {
                    isUploading = true
                    errorMessage = nil
                    
                    do {
                        if let uid = formViewModel.currentUserId {
                            // Add locally first for immediate UI update
                            formViewModel.addProjectLocally(title: title, description: description, toolsString: toolsInput, link: link)
                            
                            // Save to Firestore
                            try await formViewModel.saveProject(title: title, description: description, toolsString: toolsInput, link: link, userId: uid)
                            
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
                            print("Project save error: \(error)")
                        }
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isValid || isUploading)
        }
        .padding()
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
    }
}
