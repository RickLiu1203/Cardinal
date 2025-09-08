//
//  FormViewModel.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//


import Foundation

class FormViewModel: ObservableObject {
    enum SectionType: String, CaseIterable, Identifiable, Equatable {
        case personalDetails
        case experience
        case projects
        case skills
        case resume
        case formField
        case list
        case sectionTypeSelector
        var id: String { rawValue }
        var title: String {
            switch self {
            case .personalDetails: return "Personal Details"
            case .experience: return "Experience"
            case .projects: return "Projects"
            case .skills: return "Skills"
            case .resume: return "Resume"
            case .formField: return "Form Field"
            case .list: return "List"
            case .sectionTypeSelector: return "Section Type Selector"
            }
        }
    }
    @Published var selectedSections: [SectionType] = []
    var availableSections: [SectionType] {
        SectionType.allCases.filter { type in
            !selectedSections.contains(type)
        }
    }
    func addSection(_ type: SectionType) {
        guard !selectedSections.contains(type) else { return }
        selectedSections.append(type)
    }
}