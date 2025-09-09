//
//  ExperiencesView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI

struct ExperiencesView: View {
    let experiences: [PortfolioView.PresentableExperience]

    var body: some View {
        if !experiences.isEmpty {
            Section(header: Text("Experience")) {
                ForEach(experiences) { exp in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exp.role)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(exp.company)
                            .font(.footnote)
                        Text(formatPeriod(startDateString: exp.startDateString, endDateString: exp.endDateString))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        if let desc = exp.description, !desc.isEmpty {
                            Text(desc)
                                .font(.footnote)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func formatPeriod(startDateString: String?, endDateString: String?) -> String {
        let start = startDateString ?? ""
        let end = endDateString ?? "Present"
        return "\(start) – \(end)"
    }
}

