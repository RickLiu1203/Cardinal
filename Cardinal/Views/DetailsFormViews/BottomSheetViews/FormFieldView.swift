//
//  FormFieldView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//


import SwiftUI

enum FormInputType {
    case text
    case number
    case email
    case url
    case date
}

struct FormFieldView: View {
    let title: String
    @Binding var text: String
    let inputType: FormInputType
    let isMandatory: Bool
    
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
        case .date: return .default
        }
    }
    
    private func textAutocap(for type: FormInputType) -> TextInputAutocapitalization {
        switch type {
        case .email, .url: return .never
        default: return .sentences
        }
    }
}
