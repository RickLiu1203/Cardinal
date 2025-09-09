//
//  SectionTypeSelectorView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//


import SwiftUI

struct SectionTypeSelectorView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var formViewModel: FormViewModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List(formViewModel.availableSections, id: \.id) { section in
                NavigationLink(section.title) {
                    destination(for: section)
                        .environmentObject(formViewModel)
                }
            }
            .navigationTitle("Add Section")
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func destination(for section: FormViewModel.SectionType) -> some View {
        switch section {
        case .personalDetails: PersonalDetailsSheetView(onAdded: { isPresented = false })
        case .experience: ExperienceSheetView(onAdded: { isPresented = false })
        case .projects: ProjectSheetView(onAdded: { isPresented = false })
        case .skills: SkillsSheetView(onAdded: { isPresented = false })
        case .resume: ResumeSheetView(onAdded: { isPresented = false })
        case .about: AboutSheetView(onAdded: { isPresented = false })
        }
    }
}
