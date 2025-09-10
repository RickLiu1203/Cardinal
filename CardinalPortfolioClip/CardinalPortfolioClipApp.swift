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
    @State private var didLogOpen: Bool = false
    init() {}

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .center) {
                portfolioContent
                
                if showLandingModal {
                    Color("BackgroundPrimary")
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        LandingModalView(isPresented: $showLandingModal) {
                            // Dismiss modal and log a visit once
                            showLandingModal = false
                            if !didLogOpen, let ownerId = AnalyticsManager.shared.ownerId ?? vm.lastOwnerId, !ownerId.isEmpty {
                                AnalyticsManager.shared.logEvent(action: "page_view")
                                didLogOpen = true
                            }
                        }
                        Spacer()
                    }
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .animation(.none, value: showLandingModal)
            .onAppear {
                // Show modal only if we don't have a cached visitor name
                showLandingModal = AnalyticsManager.shared.visitorName.isEmpty
            }
            .onOpenURL { url in
                handleOpenURL(url)
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                if let url = (activity.webpageURL ?? activity.referrerURL) {
                    handleOpenURL(url)
                }
            }
        }
    }
    
    // MARK: - Computed Views
    @ViewBuilder
    private var portfolioContent: some View {
        PortfolioView(
            overridePersonalDetails: personalDetailsOverride,
            overrideAbout: aboutOverride,
            overrideExperiences: experiencesOverride,
            overrideResume: resumeOverride,
            overrideSkills: skillsOverride,
            overrideProjects: projectsOverride,
            overrideSectionOrder: sectionOrderOverride
        )
    }
    
    // MARK: - Data Overrides (computed lazily)
    private var personalDetailsOverride: PortfolioView.PresentablePersonalDetails? {
        guard let pd = vm.personalDetails else { return nil }
        return .init(
            firstName: pd.firstName,
            lastName: pd.lastName,
            subtitle: pd.subtitle,
            email: pd.email,
            linkedIn: pd.linkedIn,
            phoneNumber: pd.phoneNumber,
            github: pd.github,
            website: pd.website
        )
    }
    
    private var aboutOverride: PortfolioView.PresentableAbout? {
        vm.about.map { PortfolioView.PresentableAbout(header: $0.header, subtitle: $0.subtitle, body: $0.body) }
    }
    
    private var experiencesOverride: [PortfolioView.PresentableExperience] {
        vm.experiences.map { item in
            PortfolioView.PresentableExperience(
                id: item.id,
                company: item.company,
                role: item.role,
                startDateString: item.startDate,
                endDateString: item.endDate,
                description: item.description,
                skills: item.skills
            )
        }
    }
    
    private var resumeOverride: PortfolioView.PresentableResume? {
        vm.resume.map { PortfolioView.PresentableResume(fileName: $0.fileName, downloadURL: $0.downloadURL, uploadedAt: $0.uploadedAt) }
    }
    
    private var skillsOverride: PortfolioView.PresentableSkills? {
        vm.skills.isEmpty ? nil : PortfolioView.PresentableSkills(skills: vm.skills)
    }
    
    private var projectsOverride: [PortfolioView.PresentableProject] {
        vm.projects.map { PortfolioView.PresentableProject(id: $0.id, title: $0.title, description: $0.description, tools: $0.tools, link: $0.link) }
    }
    
    private var sectionOrderOverride: [PortfolioView.SectionType]? {
        vm.sectionOrder.isEmpty ? nil : vm.sectionOrder.compactMap { PortfolioView.SectionType(rawValue: $0) }
    }
    
    @ViewBuilder
    private var loadingView: some View { EmptyView() }
    
    // MARK: - Helper Methods
    private func setupInitialState() {}
    
    private func handleOpenURL(_ url: URL) {
        vm.apply(url: url)
        if let ownerId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "id" })?.value, !ownerId.isEmpty {
            AnalyticsManager.shared.ownerId = ownerId
            // If we already have a name, log immediately; otherwise, wait for modal submit
            if !showLandingModal, !didLogOpen {
                AnalyticsManager.shared.logEvent(action: "page_view")
                didLogOpen = true
            }
        }
    }
}
