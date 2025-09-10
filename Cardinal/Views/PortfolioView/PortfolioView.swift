//
//  PortfolioView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI
import SafariServices
#if !APPCLIP
import FirebaseAuth
#endif

struct PortfolioView: View {
    enum SectionType: String, CaseIterable, Identifiable {
        case personalDetails
        case experience
        case projects
        case skills
        case about
        var id: String { rawValue }
    }
    
    struct PresentablePersonalDetails: Equatable {
        let firstName: String
        let lastName: String
        let subtitle: String
        let email: String
        let linkedIn: String
        let phoneNumber: String
        let github: String
        let website: String
    }
    struct PresentableAbout: Equatable {
        let header: String
        let subtitle: String
        let body: String
    }
    struct PresentableExperience: Equatable, Identifiable {
        let id: String
        let company: String
        let role: String
        let startDateString: String?
        let endDateString: String?
        let description: String?
        let skills: [String]?
    }
    struct PresentableResume: Equatable {
        let fileName: String
        let downloadURL: String
        let uploadedAt: String // formatted date string
    }
    struct PresentableSkills: Equatable {
        let skills: [String]
    }
    struct PresentableProject: Equatable, Identifiable {
        let id: String
        let title: String
        let description: String?
        let tools: [String]
        let link: String?
    }
    
    // Optional overrides for App Clip or callers that want to inject data directly
    private let overridePersonalDetails: PresentablePersonalDetails?
    private let overrideAbout: PresentableAbout?
    private let overrideExperiences: [PresentableExperience]?
    private let overrideResume: PresentableResume?
    private let overrideSkills: PresentableSkills?
    private let overrideProjects: [PresentableProject]?
    private let overrideSectionOrder: [SectionType]?
    
    #if !APPCLIP
    @EnvironmentObject var formViewModel: FormViewModel
    #endif
    
    @State private var showingSafariView = false
    @State private var safariURL: URL?
    
    init(overridePersonalDetails: PresentablePersonalDetails? = nil,
         overrideAbout: PresentableAbout? = nil,
         overrideExperiences: [PresentableExperience]? = nil,
         overrideResume: PresentableResume? = nil,
         overrideSkills: PresentableSkills? = nil,
         overrideProjects: [PresentableProject]? = nil,
         overrideSectionOrder: [SectionType]? = nil) {
        self.overridePersonalDetails = overridePersonalDetails
        self.overrideAbout = overrideAbout
        self.overrideExperiences = overrideExperiences
        self.overrideResume = overrideResume
        self.overrideSkills = overrideSkills
        self.overrideProjects = overrideProjects
        self.overrideSectionOrder = overrideSectionOrder
    }
    
    private var effectivePersonalDetails: PresentablePersonalDetails? {
        if let injected = overridePersonalDetails { return injected }
        #if !APPCLIP
        if let pd = formViewModel.personalDetails {
            return .init(firstName: pd.firstName, lastName: pd.lastName, subtitle: pd.subtitle, email: pd.email, linkedIn: pd.linkedIn, phoneNumber: pd.phoneNumber, github: pd.github, website: pd.website)
        }
        #endif
        return nil
    }
    private var effectiveAbout: PresentableAbout? {
        if let injected = overrideAbout { return injected }
        #if !APPCLIP
        if let about = formViewModel.about {
            return .init(header: about.header, subtitle: about.subtitle, body: about.body)
        }
        #endif
        return nil
    }
    private var effectiveExperiences: [PresentableExperience] {
        if let injected = overrideExperiences { return injected }
        #if !APPCLIP
        return formViewModel.experiences.map { e in
            return .init(id: e.id, company: e.company, role: e.role, startDateString: e.startDateString, endDateString: e.endDateString, description: e.description, skills: e.skills)
        }
        #else
        return []
        #endif
    }
    private var effectiveResume: PresentableResume? {
        if let injected = overrideResume { return injected }
        #if !APPCLIP
        if let resume = formViewModel.resume {
            let df = DateFormatter()
            df.dateStyle = .medium
            return .init(fileName: resume.fileName, downloadURL: resume.downloadURL, uploadedAt: df.string(from: resume.uploadedAt))
        }
        #endif
        return nil
    }
    private var effectiveSkills: PresentableSkills? {
        if let injected = overrideSkills { return injected }
        #if !APPCLIP
        if let skills = formViewModel.skills?.skills, !skills.isEmpty {
            return .init(skills: skills)
        }
        #endif
        return nil
    }
    private var effectiveProjects: [PresentableProject] {
        if let injected = overrideProjects { return injected }
        #if !APPCLIP
        return formViewModel.projects.map { p in
            return .init(id: p.id, title: p.title, description: p.description, tools: p.tools, link: p.link)
        }
        #endif
        return []
    }
    
    private var effectiveSectionOrder: [SectionType] {
        #if !APPCLIP
        // For main app, use FormViewModel's section order
        let formViewModelOrder = formViewModel.selectedSections.compactMap { formSectionType in
            return SectionType(rawValue: formSectionType.rawValue)
        }
        return formViewModelOrder.filter { sectionHasData($0) }
        #else
        // For App Clip, use injected section order if available, otherwise default order.
        // Additionally, if there is data for a section (e.g. projects) but it is missing
        // from the injected order, append it to ensure important data is visible.
        if let injectedOrder = overrideSectionOrder {
            var order = injectedOrder
            if sectionHasData(.projects), order.contains(.projects) == false { order.append(.projects) }
            if sectionHasData(.skills), order.contains(.skills) == false { order.append(.skills) }
            if sectionHasData(.about), order.contains(.about) == false { order.append(.about) }
            if sectionHasData(.experience), order.contains(.experience) == false { order.append(.experience) }
            if sectionHasData(.personalDetails), order.contains(.personalDetails) == false { order.append(.personalDetails) }
            return order.filter { sectionHasData($0) }
        } else {
            let defaultOrder: [SectionType] = [.personalDetails, .about, .experience, .skills, .projects]
            return defaultOrder.filter { sectionHasData($0) }
        }
        #endif
    }
    
    private func sectionHasData(_ sectionType: SectionType) -> Bool {
        switch sectionType {
        case .personalDetails:
            return effectivePersonalDetails != nil
        case .about:
            return effectiveAbout != nil
        case .experience:
            return !effectiveExperiences.isEmpty
        case .skills:
            return effectiveSkills != nil
        case .projects:
            return !effectiveProjects.isEmpty
        }
    }
    
    @ViewBuilder
    private func sectionView(for sectionType: SectionType) -> some View {
        switch sectionType {
        case .personalDetails:
            if let pd = effectivePersonalDetails {
                PersonalDetailsView(personalDetails: pd)
                    .foregroundColor(Color("TextPrimary"))
            }
            
        case .about:
            if let about = effectiveAbout {
                AboutView(about: about, resume: effectiveResume, onViewTapped: { url in
                    AnalyticsManager.shared.logEvent(action: "view_resume", meta: ["url": url.absoluteString])
                    UIApplication.shared.open(url)
                })
                    .foregroundColor(Color("TextPrimary"))
            }
            
        case .experience:
            let exps = effectiveExperiences
            if !exps.isEmpty {
                ExperiencesView(experiences: exps)
                    .foregroundColor(Color("TextPrimary"))
            }
            
            
        case .skills:
            if let skillsData = effectiveSkills {
                SkillsView(skills: skillsData)
                    .foregroundColor(Color("TextPrimary"))
            }
            
        case .projects:
            let projects = effectiveProjects
            if !projects.isEmpty {
                ProjectsView(projects: projects)
                    .foregroundColor(Color("TextPrimary"))
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(effectiveSectionOrder, id: \.id) { sectionType in
                        sectionView(for: sectionType)
                    }
                    
                    if effectiveSectionOrder.isEmpty {
                        Section {
                            #if !APPCLIP
                            Text("No details yet. Add your info in the Details tab.")
                                .foregroundColor(Color("TextPrimary"))
                            #endif
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("BackgroundPrimary"))
            #if !APPCLIP
            .onAppear {
                if let uid = Auth.auth().currentUser?.uid {
                    Task {
                        await formViewModel.fetchPersonalDetails(userId: uid)
                        await formViewModel.fetchAbout(userId: uid)
                        await formViewModel.fetchExperiences(userId: uid)
                        await formViewModel.fetchResume(userId: uid)
                        await formViewModel.fetchSkills(userId: uid)
                        await formViewModel.fetchProjects(userId: uid)
                        
                        await formViewModel.fetchSectionOrder(userId: uid)
                    }
                }
            }
            #endif
        }
        .sheet(isPresented: $showingSafariView) {
            if let url = safariURL {
                SafariView(url: url)
            }
        }
    }
    
    private func presentPDFInSafariView(url: URL) {
        safariURL = url
        showingSafariView = true
    }
}

private func formatPeriod(startDateString: String?, endDateString: String?) -> String {
    let start = startDateString ?? ""
    let end = endDateString ?? "Present"
    return "\(start) – \(end)"
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.preferredBarTintColor = UIColor.systemBackground
        safariViewController.preferredControlTintColor = UIColor.systemBlue
        return safariViewController
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    PortfolioView(
        overridePersonalDetails: PortfolioView.PresentablePersonalDetails(
            firstName: "John",
            lastName: "Doe",
            subtitle: "Computer Engineering @ UWaterloo",
            email: "john.doe@example.com",
            linkedIn: "https://linkedin.com/in/johndoe",
            phoneNumber: "+1 (555) 123-4567",
            github: "https://github.com/johndoe",
            website: "https://johndoe.dev"
        ),
        overrideAbout: PortfolioView.PresentableAbout(
            header: "HIGHLIGHTS",
            subtitle: "what i'm most proud of",
            body: "I'm a **passionate software developer** with experience in iOS development and web technologies. I love building **innovative solutions** that make a difference."
        ),
        overrideExperiences: [
            PortfolioView.PresentableExperience(
                id: "1",
                company: "Tech Corp",
                role: "iOS Developer",
                startDateString: "Jan 2023",
                endDateString: nil,
                description: "Developing cutting-edge mobile applications using SwiftUI and UIKit.",
                skills: ["Swift", "SwiftUI", "UIKit", "iOS"]
            ),
            PortfolioView.PresentableExperience(
                id: "2",
                company: "StartupXYZ",
                role: "Junior Developer",
                startDateString: "Jun 2022",
                endDateString: "Dec 2022",
                description: "Built web applications using React and Node.js.",
                skills: ["React", "Node.js", "JavaScript"]
            )
        ],
        overrideResume: PortfolioView.PresentableResume(
            fileName: "John_Doe_Resume.pdf",
            downloadURL: "https://example.com/resume.pdf",
            uploadedAt: "Dec 15, 2024"
        ),
        overrideSkills: PortfolioView.PresentableSkills(
            skills: ["Swift", "SwiftUI", "UIKit", "React", "Node.js", "Firebase", "Git"]
        ),
        overrideProjects: [
            PortfolioView.PresentableProject(
                id: "1",
                title: "Weather App",
                description: "A beautiful weather app built with SwiftUI featuring real-time weather data and forecasts.",
                tools: ["SwiftUI", "CoreLocation", "WeatherKit"],
                link: "https://github.com/johndoe/weather-app"
            ),
            PortfolioView.PresentableProject(
                id: "2",
                title: "Task Manager",
                description: "A productivity app for managing daily tasks with cloud sync.",
                tools: ["UIKit", "Core Data", "CloudKit"],
                link: "https://apps.apple.com/app/taskmanager"
            )
        ],
        overrideSectionOrder: [.personalDetails, .about, .experience, .skills, .projects]
    )
}

