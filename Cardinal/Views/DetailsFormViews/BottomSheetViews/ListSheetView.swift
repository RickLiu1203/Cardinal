//
//  ListSheetView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//


import SwiftUI

struct ListSheetView: View {
    var onAdded: (() -> Void)? = nil
    @EnvironmentObject var formViewModel: FormViewModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 16) {
            Text("List")
                .font(.title2)
                .fontWeight(.bold)
            Button("Add Section") {
                formViewModel.addSection(.list)
                onAdded?()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
    }
}
