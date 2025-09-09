//
//  AboutView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI

struct AboutView: View {
    let about: PortfolioView.PresentableAbout?

    var body: some View {
        if let about = about {
            Section() {
                VStack(alignment: .leading, spacing: 6) {
                    if !about.header.isEmpty {
                        Text(about.header)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    if !about.subtitle.isEmpty {
                        Text(about.subtitle)
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    if !about.body.isEmpty {
                        Text(about.body)
                            .font(.footnote)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

#Preview {
    List {
        AboutView(
            about: PortfolioView.PresentableAbout(
                header: "About Me",
                subtitle: "Software Developer",
                body: "I'm a passionate software developer with experience in iOS development and web technologies. I love creating beautiful and functional applications."
            )
        )
    }
    .listStyle(.insetGrouped)
}
