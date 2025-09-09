//
//  PersonalDetailsView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI

struct PersonalDetailsView: View {
    let personalDetails: PortfolioView.PresentablePersonalDetails

    var body: some View {
        Section(header: Text("Personal Details")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(personalDetails.firstName) \(personalDetails.lastName)")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(personalDetails.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if !personalDetails.phoneNumber.isEmpty {
                    Text(personalDetails.phoneNumber)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if !personalDetails.linkedIn.isEmpty {
                    Link(destination: URL(string: personalDetails.linkedIn) ?? URL(string: "https://linkedin.com")!) {
                        HStack {
                            Image(systemName: "link")
                                .font(.caption)
                            Text("LinkedIn")
                                .font(.subheadline)
                        }
                        .foregroundColor(.blue)
                    }
                }
                if !personalDetails.github.isEmpty {
                    Link(destination: URL(string: personalDetails.github) ?? URL(string: "https://github.com")!) {
                        HStack {
                            Image(systemName: "link")
                                .font(.caption)
                            Text("GitHub")
                                .font(.subheadline)
                        }
                        .foregroundColor(.blue)
                    }
                }
                if !personalDetails.website.isEmpty {
                    Link(destination: URL(string: personalDetails.website) ?? URL(string: "https://example.com")!) {
                        HStack {
                            Image(systemName: "link")
                                .font(.caption)
                            Text("Website")
                                .font(.subheadline)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

