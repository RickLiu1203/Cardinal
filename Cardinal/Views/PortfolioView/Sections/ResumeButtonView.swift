//
//  ResumeButtonView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI

struct ResumeButtonView: View {
    let resume: PortfolioView.PresentableResume
    let onViewTapped: (URL) -> Void

    var body: some View {
        Section(header: Text("Resume")) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(resume.fileName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Uploaded: \(resume.uploadedAt)")
                            .font(.footnote)
                            .foregroundColor(Color("TextPrimary"))
                    }
                    Spacer()
                    Button("View") {
                        if let url = URL(string: resume.downloadURL) {
                            onViewTapped(url)
                        }
                    }
                    .font(.footnote)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    List {
        ResumeButtonView(
            resume: PortfolioView.PresentableResume(
                fileName: "John_Doe_Resume.pdf",
                downloadURL: "https://example.com/resume.pdf",
                uploadedAt: "Dec 15, 2024"
            ),
            onViewTapped: { url in
                print("Would open: \(url)")
            }
        )
    }
    .listStyle(.insetGrouped)
}

