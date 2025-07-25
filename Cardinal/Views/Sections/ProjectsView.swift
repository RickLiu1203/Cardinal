//
//  ProjectsView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-07-24.
//

import SwiftUI

struct ProjectsView: View {
    var body: some View {
        VStack (alignment: .leading, spacing: 48){
            // title
            SectionHeaderView(titleText: "PROJECTS", subtitleText: "what i've worked on")

            // projects
            VStack (alignment: .leading, spacing: 12){

            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .topLeading
        )
        .padding(.horizontal, 36)
        .padding(.top, 36)
        .padding(.bottom, 48)
    }
}