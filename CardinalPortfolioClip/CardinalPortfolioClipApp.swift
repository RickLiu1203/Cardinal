//
//  CardinalPortfolioClipApp.swift
//  CardinalPortfolioClip
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI

@main
struct CardinalPortfolioClipApp: App {
    @StateObject private var vm = PortfolioViewModel()
    init() {}

    var body: some Scene {
        WindowGroup {
            Group {
                let injectedBlocks = vm.textBlocks.map { PortfolioView.PresentableTextBlock(id: $0.id, header: $0.header, body: $0.body) }
                let injectedExps = vm.experiences.map { item in
                    PortfolioView.PresentableExperience(id: item.id, company: item.company, role: item.role, startDateString: item.startDate, endDateString: item.endDate, description: item.description)
                }
                let injectedResume = vm.resume.map { PortfolioView.PresentableResume(fileName: $0.fileName, downloadURL: $0.downloadURL, uploadedAt: $0.uploadedAt) }
                let injectedSkills = vm.skills.isEmpty ? nil : PortfolioView.PresentableSkills(skills: vm.skills)
                let injectedProjects = vm.projects.map { PortfolioView.PresentableProject(id: $0.id, title: $0.title, description: $0.description, tools: $0.tools, link: $0.link) }
                let injectedSectionOrder = vm.sectionOrder.isEmpty ? nil : vm.sectionOrder.compactMap { PortfolioView.SectionType(rawValue: $0) }
                
                if let pd = vm.personalDetails {
                    PortfolioView(
                        overridePersonalDetails: .init(
                            firstName: pd.firstName,
                            lastName: pd.lastName,
                            email: pd.email,
                            linkedIn: pd.linkedIn,
                            phoneNumber: pd.phoneNumber,
                            github: pd.github,
                            website: pd.website
                        ),
                        overrideTextBlocks: injectedBlocks,
                        overrideExperiences: injectedExps,
                        overrideResume: injectedResume,
                        overrideSkills: injectedSkills,
                        overrideProjects: injectedProjects,
                        overrideSectionOrder: injectedSectionOrder
                    )
                } else {
                    PortfolioView(
                        overridePersonalDetails: nil,
                        overrideTextBlocks: injectedBlocks,
                        overrideExperiences: injectedExps,
                        overrideResume: injectedResume,
                        overrideSkills: injectedSkills,
                        overrideProjects: injectedProjects,
                        overrideSectionOrder: injectedSectionOrder
                    )
                }
            }
            .onAppear {
                let injectedSectionOrder = vm.sectionOrder.isEmpty ? nil : vm.sectionOrder.compactMap { PortfolioView.SectionType(rawValue: $0) }
                print("📱 App Clip using section order: \(injectedSectionOrder?.map { $0.rawValue } ?? ["default"])")
            }
            .onOpenURL { url in
                vm.apply(url: url)
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                if let url = (activity.webpageURL ?? activity.referrerURL) {
                    vm.apply(url: url)
                }
            }
        }
    }
}
