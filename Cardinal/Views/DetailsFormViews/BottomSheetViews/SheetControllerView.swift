//
//  SheetControllerView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//


import SwiftUI

struct SheetControllerView: View {
    @EnvironmentObject var formViewModel: FormViewModel
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
        case .personalDetails: PersonalDetailsSheetView()
        case .experience: ExperienceSheetView()
        case .projects: ProjectSheetView()
        case .skills: SkillsSheetView()
        case .resume: ResumeSheetView()
        case .formField: FormFieldView()
        case .list: ListSheetView()
        case .sectionTypeSelector: SectionTypeSelectorView()
        }
    }
}