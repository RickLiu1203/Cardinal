//
//  TextBlockSheetView.swift
//  Cardinal
//
//  Created by Assistant on 2025-09-08.
//

import SwiftUI
import FirebaseAuth

struct TextBlockSheetView: View {
    var onAdded: (() -> Void)? = nil
    var initialData: FormViewModel.TextBlockData? = nil
    var isEditing: Bool = false
    @EnvironmentObject var formViewModel: FormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var header: String = ""
    @State private var bodyText: String = ""
    @State private var didPrefill: Bool = false
    var body: some View {
        VStack(spacing: 16) {
            Text(isEditing ? "Edit Text Block" : "Text Block")
                .font(.title2)
                .fontWeight(.bold)
            FormFieldView(title: "Header", text: $header, inputType: .text, isMandatory: false)
            FormFieldView(title: "Body", text: $bodyText, inputType: .text, isMandatory: false, multiline: true)
            Button(isEditing ? "Save Changes" : "Add Section") {
                if isEditing, let id = initialData?.id {
                    Task {
                        await formViewModel.updateTextBlock(id: id, header: header, body: bodyText)
                        dismiss()
                    }
                } else {
                    formViewModel.addTextBlockLocally(header: header, body: bodyText)
                    onAdded?()
                    dismiss()
                    if let uid = Auth.auth().currentUser?.uid {
                        Task { try? await formViewModel.saveTextBlock(header, body: bodyText, userId: uid) }
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
        .onAppear {
            if !didPrefill, let initial = initialData {
                header = initial.header
                bodyText = initial.body
                didPrefill = true
            }
        }
    }
}


