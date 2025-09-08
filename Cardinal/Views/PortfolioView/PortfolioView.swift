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
        case resume
        case textBlock
        var id: String { rawValue }
    }
    
    struct PresentablePersonalDetails: Equatable {
        let firstName: String
        let lastName: String
        let email: String
        let linkedIn: String
        let phoneNumber: String
        let github: String
        let website: String
    }
    struct PresentableTextBlock: Equatable, Identifiable {
        let id: String
        let header: String
        let body: String
    }
    struct PresentableExperience: Equatable, Identifiable {
        let id: String
        let company: String
        let role: String
        let startDateString: String?
        let endDateString: String?
        let description: String?
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
    private let overrideTextBlocks: [PresentableTextBlock]?
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
         overrideTextBlocks: [PresentableTextBlock]? = nil,
         overrideExperiences: [PresentableExperience]? = nil,
         overrideResume: PresentableResume? = nil,
         overrideSkills: PresentableSkills? = nil,
         overrideProjects: [PresentableProject]? = nil,
         overrideSectionOrder: [SectionType]? = nil) {
        self.overridePersonalDetails = overridePersonalDetails
        self.overrideTextBlocks = overrideTextBlocks
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
            return .init(firstName: pd.firstName, lastName: pd.lastName, email: pd.email, linkedIn: pd.linkedIn, phoneNumber: pd.phoneNumber, github: pd.github, website: pd.website)
        }
        #endif
        return nil
    }
    private var effectiveTextBlocks: [PresentableTextBlock] {
        if let injected = overrideTextBlocks { return injected }
        #if !APPCLIP
        return formViewModel.textBlocks.map { .init(id: $0.id, header: $0.header, body: $0.body) }
        #else
        return []
        #endif
    }
    private var effectiveExperiences: [PresentableExperience] {
        if let injected = overrideExperiences { return injected }
        #if !APPCLIP
        return formViewModel.experiences.map { e in
            return .init(id: e.id, company: e.company, role: e.role, startDateString: e.startDateString, endDateString: e.endDateString, description: e.description)
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
        #else
        return []
        #endif
    }
    
    private var effectiveSectionOrder: [SectionType] {
        #if !APPCLIP
        // For main app, use FormViewModel's section order
        let formViewModelOrder = formViewModel.selectedSections.compactMap { formSectionType in
            return SectionType(rawValue: formSectionType.rawValue)
        }
        return formViewModelOrder.filter { sectionHasData($0) }
        #else
        // For App Clip, use injected section order if available, otherwise default order
        if let injectedOrder = overrideSectionOrder {
            return injectedOrder.filter { sectionHasData($0) }
        } else {
            let defaultOrder: [SectionType] = [.personalDetails, .textBlock, .experience, .resume, .skills, .projects]
            return defaultOrder.filter { sectionHasData($0) }
        }
        #endif
    }
    
    private func sectionHasData(_ sectionType: SectionType) -> Bool {
        switch sectionType {
        case .personalDetails:
            return effectivePersonalDetails != nil
        case .textBlock:
            return !effectiveTextBlocks.isEmpty
        case .experience:
            return !effectiveExperiences.isEmpty
        case .resume:
            return effectiveResume != nil
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
                Section(header: Text("Personal Details")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(pd.firstName) \(pd.lastName)")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(pd.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if !pd.phoneNumber.isEmpty {
                            Text(pd.phoneNumber)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        if !pd.linkedIn.isEmpty {
                            Link(destination: URL(string: pd.linkedIn) ?? URL(string: "https://linkedin.com")!) {
                                HStack {
                                    Image(systemName: "link")
                                        .font(.caption)
                                    Text("LinkedIn")
                                        .font(.subheadline)
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        if !pd.github.isEmpty {
                            Link(destination: URL(string: pd.github) ?? URL(string: "https://github.com")!) {
                                HStack {
                                    Image(systemName: "link")
                                        .font(.caption)
                                    Text("GitHub")
                                        .font(.subheadline)
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        if !pd.website.isEmpty {
                            Link(destination: URL(string: pd.website) ?? URL(string: "https://example.com")!) {
                                HStack {
                                    Image(systemName: "link")
                                        .font(.caption)
                                    Text("Website")
                                        .font(.subheadline)
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
        case .textBlock:
            let blocks = effectiveTextBlocks
            if !blocks.isEmpty {
                Section(header: Text("Text Blocks")) {
                    ForEach(blocks) { block in
                        VStack(alignment: .leading, spacing: 6) {
                            if !block.header.isEmpty {
                                Text(block.header)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            if !block.body.isEmpty {
                                Text(block.body)
                                    .font(.footnote)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            
        case .experience:
            let exps = effectiveExperiences
            if !exps.isEmpty {
                Section(header: Text("Experience")) {
                    ForEach(exps) { exp in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exp.role)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(exp.company)
                                .font(.footnote)
                            Text(formatPeriod(startDateString: exp.startDateString, endDateString: exp.endDateString))
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            if let desc = exp.description, !desc.isEmpty {
                                Text(desc)
                                    .font(.footnote)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            
        case .resume:
            if let resume = effectiveResume {
                Section(header: Text("Resume")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(resume.fileName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text("Uploaded: \(resume.uploadedAt)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("View") {
                                if let url = URL(string: resume.downloadURL) {
                                    #if APPCLIP
                                    // For App Clip, use SFSafariViewController for in-app PDF viewing
                                    presentPDFInSafariView(url: url)
                                    #else
                                    // For main app, open in external app
                                    UIApplication.shared.open(url)
                                    #endif
                                }
                            }
                            .font(.footnote)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
        case .skills:
            if let skillsData = effectiveSkills {
                Section(header: Text("Skills")) {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 80), spacing: 8)
                    ], spacing: 8) {
                        ForEach(skillsData.skills, id: \.self) { skill in
                            Text(skill)
                                .font(.footnote)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(16)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
        case .projects:
            let projects = effectiveProjects
            if !projects.isEmpty {
                Section(header: Text("Projects")) {
                    ForEach(projects) { project in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(project.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            if let description = project.description, !description.isEmpty {
                                Text(description)
                                    .font(.footnote)
                            }
                            
                            if !project.tools.isEmpty {
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 60), spacing: 6)
                                ], spacing: 6) {
                                    ForEach(project.tools, id: \.self) { tool in
                                        Text(tool)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.green.opacity(0.1))
                                            .foregroundColor(.green)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                            
                            if let link = project.link, !link.isEmpty {
                                Link(destination: URL(string: link) ?? URL(string: "https://example.com")!) {
                                    HStack {
                                        Image(systemName: "link")
                                            .font(.caption)
                                        Text(link)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(effectiveSectionOrder, id: \.id) { sectionType in
                    sectionView(for: sectionType)
                }
                
                if effectiveSectionOrder.isEmpty {
                    Section {
                        #if APPCLIP
                        Text("No details yet.")
                            .foregroundColor(.secondary)
                        Text("Open from your link to see details.")
                            .foregroundColor(.secondary)
                        #else
                        Text("No details yet. Add your info in the Details tab.")
                            .foregroundColor(.secondary)
                        #endif
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Portfolio")
            #if !APPCLIP
            .onAppear {
                if let uid = Auth.auth().currentUser?.uid {
                    Task {
                        // Fetch all data first
                        await formViewModel.fetchPersonalDetails(userId: uid)
                        await formViewModel.fetchTextBlocks(userId: uid)
                        await formViewModel.fetchExperiences(userId: uid)
                        await formViewModel.fetchResume(userId: uid)
                        await formViewModel.fetchSkills(userId: uid)
                        await formViewModel.fetchProjects(userId: uid)
                        
                        // Then apply the saved section order after all data is loaded
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

