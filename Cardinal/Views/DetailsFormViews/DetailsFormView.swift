//
//  DetailsFormView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//


import SwiftUI

struct DetailsFormView: View {
    @EnvironmentObject var formViewModel: FormViewModel
    var body: some View {
        VStack(spacing: 16) {
            if formViewModel.selectedSections.isEmpty {
                Text("No sections added")
                    .foregroundColor(.secondary)
            } else {
                List {
                    ForEach(formViewModel.selectedSections, id: \.id) { section in
                        Text(section.title)
                    }
                }
                .listStyle(.insetGrouped)
            }
            AddSectionView()
        }
        .padding()
        .navigationTitle("Details")
    }
}