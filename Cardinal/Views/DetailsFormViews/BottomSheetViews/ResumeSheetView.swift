//
//  ResumeSheetView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//


import SwiftUI

struct ResumeSheetView: View {
    var onAdded: (() -> Void)? = nil
    @EnvironmentObject var formViewModel: FormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var fileName = ""
    @State private var selectedFileURL: URL?
    @State private var fileData: Data?
    @State private var isUploading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Resume")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                FormFieldView(
                    title: "Resume File",
                    text: $fileName,
                    inputType: .file,
                    isMandatory: true,
                    onFileSelected: { url in
                        selectedFileURL = url
                        fileName = url.lastPathComponent
                        errorMessage = nil // Clear any previous errors
                        
                        // Copy file data immediately while we have access
                        do {
                            fileData = try Data(contentsOf: url)
                            print("📁 File data loaded: \(fileData?.count ?? 0) bytes")
                        } catch {
                            errorMessage = "Failed to read file: \(error.localizedDescription)"
                            print("❌ File read error: \(error)")
                        }
                    }
                )
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            Button(isUploading ? "Uploading..." : "Add Section") {
                if let data = fileData {
                    Task {
                        isUploading = true
                        errorMessage = nil
                        
                        do {
                            if let uid = formViewModel.currentUserId {
                                print("🔐 User authenticated: \(uid)")
                                try await formViewModel.saveResume(fileName: fileName, fileData: data, userId: uid)
                                await MainActor.run {
                                    isUploading = false
                                    onAdded?()
                                    dismiss()
                                }
                            } else {
                                print("❌ No user authenticated")
                                await MainActor.run {
                                    isUploading = false
                                    errorMessage = "No user logged in"
                                }
                            }
                        } catch {
                            await MainActor.run {
                                isUploading = false
                                errorMessage = "Upload failed: \(error.localizedDescription)"
                                print("Resume upload error: \(error)")
                            }
                        }
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(fileData == nil || fileName.isEmpty || isUploading)
        }
        .padding()
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
    }
}
