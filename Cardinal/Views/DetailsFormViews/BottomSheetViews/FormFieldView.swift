//
//  FormFieldView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//


import SwiftUI
import UniformTypeIdentifiers

enum FormInputType {
    case text
    case number
    case email
    case url
    case date
    case file
}

struct FormFieldView: View {
    let title: String
    @Binding var text: String
    let inputType: FormInputType
    let isMandatory: Bool
    let multiline: Bool
    let onFileSelected: ((URL) -> Void)?

    init(title: String, text: Binding<String>, inputType: FormInputType, isMandatory: Bool, multiline: Bool = false, onFileSelected: ((URL) -> Void)? = nil) {
        self.title = title
        self._text = text
        self.inputType = inputType
        self.isMandatory = isMandatory
        self.multiline = multiline
        self.onFileSelected = onFileSelected
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if isMandatory {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
            }
            
            if inputType == .date {
                DatePicker("", selection: .constant(Date()), displayedComponents: .date)
                    .labelsHidden()
            } else if inputType == .file {
                FilePickerButton(selectedFileName: text, onFileSelected: onFileSelected)
            } else if multiline {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .frame(minHeight: 140)
                        .textInputAutocapitalization(textAutocap(for: inputType))
                        .autocorrectionDisabled(inputType != .text)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3))
                        )
                }
            } else {
                TextField("", text: $text)
                    .keyboardType(keyboardType(for: inputType))
                    .textInputAutocapitalization(textAutocap(for: inputType))
                    .autocorrectionDisabled(inputType != .text)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
    
    private func keyboardType(for type: FormInputType) -> UIKeyboardType {
        switch type {
        case .text: return .default
        case .number: return .numberPad
        case .email: return .emailAddress
        case .url: return .URL
        case .date, .file: return .default
        }
    }
    
    private func textAutocap(for type: FormInputType) -> TextInputAutocapitalization {
        switch type {
        case .email, .url: return .never
        default: return .sentences
        }
    }
}

struct FilePickerButton: View {
    let selectedFileName: String
    let onFileSelected: ((URL) -> Void)?
    @State private var isShowingDocumentPicker = false
    
    var body: some View {
        Button(action: {
            isShowingDocumentPicker = true
        }) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(.blue)
                Text(selectedFileName.isEmpty ? "Select PDF File" : selectedFileName)
                    .foregroundColor(selectedFileName.isEmpty ? .secondary : .primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .sheet(isPresented: $isShowingDocumentPicker) {
            DocumentPicker(allowedTypes: [.pdf]) { url in
                onFileSelected?(url)
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let allowedTypes: [UTType]
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes, asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.onDocumentPicked(url)
            }
        }
    }
}
