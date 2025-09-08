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
    @EnvironmentObject var formViewModel: FormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var header: String = ""
    @State private var bodyText: String = ""
    var body: some View {
        VStack(spacing: 16) {
            Text("Text Block")
                .font(.title2)
                .fontWeight(.bold)
            FormFieldView(title: "Header", text: $header, inputType: .text, isMandatory: false)
            FormFieldView(title: "Body", text: $bodyText, inputType: .text, isMandatory: false, multiline: true)
            Button("Add Section") {
                formViewModel.addTextBlockLocally(header: header, body: bodyText)
                onAdded?()
                dismiss()
                if let uid = Auth.auth().currentUser?.uid {
                    Task { try? await formViewModel.saveTextBlock(header, body: bodyText, userId: uid) }
                }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
    }
}


