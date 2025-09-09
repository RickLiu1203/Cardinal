//
//  SkillsView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI

struct SkillsView: View {
    let skills: PortfolioView.PresentableSkills

    var body: some View {
        Section(header: Text("Skills")) {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80), spacing: 8)
            ], spacing: 8) {
                ForEach(skills.skills, id: \.self) { skill in
                    Text(skill)
                        .font(.footnote)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

