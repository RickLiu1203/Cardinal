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
            Section() {
                VStack(alignment: .leading, spacing: 16) {  
                Text("Experience")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text("a timeline of my career")
                    .font(.custom("MabryPro-Regular", size: 16))
                ForEach(experiences) { exp in
                    VStack(alignment: .leading, spacing: 16) {
                        Text(exp.role)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(exp.company)
                            .font(.footnote)
                        Text(formatPeriod(startDateString: exp.startDateString, endDateString: exp.endDateString))
                            .font(.footnote)
                            .foregroundColor(Color("TextPrimary"))
                        if let desc = exp.description, !desc.isEmpty {
                            Text(desc)
                                .font(.footnote)
                            }
                        }
                    }
                }
                .padding(36)
            }
        }
    }

    private func formatPeriod(startDateString: String?, endDateString: String?) -> String {
        let start = startDateString ?? ""
        let end = endDateString ?? "Present"
        return "\(start) – \(end)"
    }
}

#Preview {
    List {
        ExperiencesView(
            experiences: [
                PortfolioView.PresentableExperience(
                    id: "1",
                    company: "Tech Corp",
                    role: "Senior iOS Developer",
                    startDateString: "Jan 2023",
                    endDateString: nil,
                    description: "Leading iOS development team and architecting scalable mobile applications using SwiftUI and UIKit."
                ),
                PortfolioView.PresentableExperience(
                    id: "2",
                    company: "StartupXYZ",
                    role: "Junior Developer",
                    startDateString: "Jun 2022",
                    endDateString: "Dec 2022",
                    description: "Built web applications using React and Node.js, collaborated with design team on user experience improvements."
                )
            ]
        )
    }
    .listStyle(.insetGrouped)
}

