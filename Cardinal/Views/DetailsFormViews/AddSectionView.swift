//
//  AddSectionView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//


import SwiftUI

struct AddSectionView: View {
    @State private var showingSheet = false
    @EnvironmentObject var formViewModel: FormViewModel
    var body: some View {
        Button {
            showingSheet = true
        } label: {
            Text("Add Section")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSheet) {
            SectionTypeSelectorView(isPresented: $showingSheet)
                .environmentObject(formViewModel)
        }
    }
}