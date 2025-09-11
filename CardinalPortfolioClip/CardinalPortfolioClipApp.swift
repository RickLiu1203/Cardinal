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
    @State private var showingSplash = true
    init() {}

    var body: some Scene {
        WindowGroup {
            if showingSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingSplash = false
                            }
                        }
                    }
            } else {
                ZStack(alignment: .center) {
                    portfolioContent
                    
                    if showLandingModal {
                        Color("BackgroundPrimary")
                            .ignoresSafeArea()
                        
                        VStack {
                            Spacer()
                            LandingModalView(isPresented: $showLandingModal, ownerId: AnalyticsManager.shared.ownerId ?? vm.lastOwnerId ?? "") {
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
                    // Initial setup - check if we already have an ownerId from a previous URL handling
                    if let existingOwnerId = AnalyticsManager.shared.ownerId, !existingOwnerId.isEmpty {
                        showLandingModal = AnalyticsManager.shared.visitorName.isEmpty
                    }
                    // Otherwise, wait for URL handling to set the modal state
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
            
            // Reset tracking state when switching portfolios
            let isNewPortfolio = AnalyticsManager.shared.ownerId != ownerId
            if isNewPortfolio {
                didLogOpen = false
            }
            
            AnalyticsManager.shared.ownerId = ownerId
            
            // Now that ownerId is set, check if we should show the modal for this specific portfolio
            let shouldShowModal = AnalyticsManager.shared.visitorName.isEmpty
            
            // Update modal state if needed
            if showLandingModal != shouldShowModal {
                showLandingModal = shouldShowModal
            }
            
            // If we already have a name for this portfolio, log immediately; otherwise, wait for modal submit
            if !shouldShowModal && !didLogOpen {
                AnalyticsManager.shared.logEvent(action: "page_view")
                didLogOpen = true
            }
        }
    }
}

// MARK: - Splash Screen
struct SplashView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            
            Image("CardinalLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BackgroundPrimary"))
    }
}
