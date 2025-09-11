//
//  CardinalPortfolioClipApp.swift
//  CardinalPortfolioClip
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI
import CoreText
import UserNotifications

@main
struct CardinalPortfolioClipApp: App {
    @UIApplicationDelegateAdaptor(ClipAppDelegate.self) var appDelegate
    @StateObject private var vm = PortfolioViewModel()
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showLandingModal: Bool = false
    @State private var didLogOpen: Bool = false
    @State private var showingSplash = true
    @State private var hasScheduledNotification = false
    init() {
    }

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
                                let currentOwnerId = AnalyticsManager.shared.ownerId ?? vm.lastOwnerId ?? ""
                                
                                showLandingModal = false
                                
                                if !didLogOpen, !currentOwnerId.isEmpty {
                                    AnalyticsManager.shared.logEvent(action: "page_view")
                                    didLogOpen = true
                                }
                                
                                if !currentOwnerId.isEmpty {
                                    let attemptKey = "notificationAttempt_\(currentOwnerId)"
                                    let lastAttempt = UserDefaults.standard.double(forKey: attemptKey)
                                    let now = Date().timeIntervalSince1970
                                    let minInterval: TimeInterval = 30
                                    
                                    if now - lastAttempt > minInterval {
                                        UserDefaults.standard.set(now, forKey: attemptKey)
                                        
                                        Task {
                                            do {
                                                await notificationManager.scheduleWelcomeNotification(
                                                    for: currentOwnerId,
                                                    personalDetails: vm.personalDetails
                                                )
                                                hasScheduledNotification = true
                                            } catch {
                                            }
                                        }
                                    }
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
        guard let ownerId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "id" })?.value, !ownerId.isEmpty else {
            return
        }
        
        let currentOwnerId = AnalyticsManager.shared.ownerId
        if currentOwnerId == ownerId && !showLandingModal {
            return
        }
        
        vm.apply(url: url)
        
        let isNewPortfolio = currentOwnerId != ownerId
        if isNewPortfolio {
            didLogOpen = false
            hasScheduledNotification = false
        }
        
        AnalyticsManager.shared.ownerId = ownerId
        
        let portfolioSpecificKey = "clipVisitorName_\(ownerId)"
        let hasVisitorName = !((UserDefaults.standard.string(forKey: portfolioSpecificKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        let shouldShowModal = !hasVisitorName
        
        if isNewPortfolio {
            showLandingModal = shouldShowModal
        } else if !showLandingModal && shouldShowModal {
            showLandingModal = shouldShowModal
        }
        
        if !shouldShowModal && !didLogOpen {
            AnalyticsManager.shared.logEvent(action: "page_view")
            didLogOpen = true
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
