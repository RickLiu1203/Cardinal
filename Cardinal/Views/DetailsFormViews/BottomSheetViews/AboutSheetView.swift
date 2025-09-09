//
//  AboutSheetView.swift
//  Cardinal
//
//  Created by Assistant on 2025-09-08.
//

import SwiftUI
import FirebaseAuth

struct AboutSheetView: View {
    var onAdded: (() -> Void)? = nil
    var initialData: FormViewModel.AboutData? = nil
    var isEditing: Bool = false
    @EnvironmentObject var formViewModel: FormViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var header: String = ""
    @State private var subtitle: String = ""
    @State private var bodyText: String = ""
    @State private var didPrefill: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text(isEditing ? "Edit About Section" : "About Section")
                .font(.title2)
                .fontWeight(.bold)
            
            FormFieldView(title: "Header", text: $header, inputType: .text, isMandatory: false)
            FormFieldView(title: "Subtitle", text: $subtitle, inputType: .text, isMandatory: false)
            FormFieldView(title: "Body", text: $bodyText, inputType: .text, isMandatory: false, multiline: true)
            
            Button(isEditing ? "Save Changes" : "Add Section") {
                if let uid = Auth.auth().currentUser?.uid {
                    Task {
                        try? await formViewModel.saveAbout(header, subtitle: subtitle, body: bodyText, userId: uid)
                        onAdded?()
                        dismiss()
                    }
                } else {
                    dismiss()
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
                subtitle = initial.subtitle
                bodyText = initial.body
                didPrefill = true
            }
        }
    }
}
