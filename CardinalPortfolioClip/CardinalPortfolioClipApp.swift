//
//  CardinalPortfolioClipApp.swift
//  CardinalPortfolioClip
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI
import CoreText

@main
struct CardinalPortfolioClipApp: App {
    @StateObject private var vm = PortfolioViewModel()
    @State private var showLandingModal: Bool = false
    init() {}

    var body: some Scene {
        WindowGroup {
            Group {
                let injectedAbout = vm.about.map { PortfolioView.PresentableAbout(header: $0.header, subtitle: $0.subtitle, body: $0.body) }
                let injectedExps = vm.experiences.map { item in
                    print("🔄 App Clip mapping experience: \(item.role) at \(item.company), skills: \(item.skills ?? [])")
                    return PortfolioView.PresentableExperience(id: item.id, company: item.company, role: item.role, startDateString: item.startDate, endDateString: item.endDate, description: item.description, skills: item.skills)
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
                            subtitle: pd.subtitle,
                            email: pd.email,
                            linkedIn: pd.linkedIn,
                            phoneNumber: pd.phoneNumber,
                            github: pd.github,
                            website: pd.website
                        ),
                        overrideAbout: injectedAbout,
                        overrideExperiences: injectedExps,
                        overrideResume: injectedResume,
                        overrideSkills: injectedSkills,
                        overrideProjects: injectedProjects,
                        overrideSectionOrder: injectedSectionOrder
                    )
                } else {
                    PortfolioView(
                        overridePersonalDetails: nil,
                        overrideAbout: injectedAbout,
                        overrideExperiences: injectedExps,
                        overrideResume: injectedResume,
                        overrideSkills: injectedSkills,
                        overrideProjects: injectedProjects,
                        overrideSectionOrder: injectedSectionOrder
                    )
                }
            }
            .onAppear {
                if UserDefaults.standard.bool(forKey: "clipNamePromptShown") == false {
                    showLandingModal = true
                    UserDefaults.standard.set(true, forKey: "clipNamePromptShown")
                }
                let injectedSectionOrder = vm.sectionOrder.isEmpty ? nil : vm.sectionOrder.compactMap { PortfolioView.SectionType(rawValue: $0) }
                print("📱 App Clip using section order: \(injectedSectionOrder?.map { $0.rawValue } ?? ["default"]) ")
            }
            .onOpenURL { url in
                vm.apply(url: url)
                if let ownerId = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "id" })?.value, ownerId.isEmpty == false {
                    AnalyticsManager.shared.ownerId = ownerId
                    AnalyticsManager.shared.logEvent(action: "page_view")
                }
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                if let url = (activity.webpageURL ?? activity.referrerURL) {
                    vm.apply(url: url)
                    if let ownerId = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "id" })?.value, ownerId.isEmpty == false {
                        AnalyticsManager.shared.ownerId = ownerId
                        AnalyticsManager.shared.logEvent(action: "page_view")
                    }
                }
            }
            .sheet(isPresented: $showLandingModal) {
                LandingModalView(isPresented: $showLandingModal)
            }
        }
    }
}
