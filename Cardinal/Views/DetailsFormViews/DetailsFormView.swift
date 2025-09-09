//
//  DetailsFormView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//


import SwiftUI
import FirebaseAuth

struct DetailsFormView: View {
    @EnvironmentObject var formViewModel: FormViewModel
    @State private var editorRoute: EditorRoute? = nil
    struct EditorRoute: Identifiable, Equatable {
        enum Kind: Equatable {
            case section(FormViewModel.SectionType)
            case editExperience(FormViewModel.ExperienceData)
            case editAbout(FormViewModel.AboutData)
            case editProject(FormViewModel.ProjectData)
        }
        let kind: Kind
        var id: String {
            switch kind {
            case .section(let type): return "section-\(type.rawValue)"
            case .editExperience(let exp): return "exp-\(exp.id)"
            case .editAbout(let about): return "about"
            case .editProject(let project): return "prj-\(project.id)"
            }
        }
        static func == (lhs: EditorRoute, rhs: EditorRoute) -> Bool { lhs.id == rhs.id }
    }
    var body: some View {
        List {
            AddSectionView()
            if formViewModel.selectedSections.isEmpty == false {
                Section {
                    ForEach(formViewModel.selectedSections, id: \.id) { section in
                        switch section {
                        case .personalDetails:
                            Group {
                                if let pd = formViewModel.personalDetails {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Personal Details")
                                            .font(.headline)
                                        Text("Name: \(pd.firstName) \(pd.lastName)")
                                            .font(.subheadline)
                                        Text("Email: \(pd.email)")
                                            .font(.subheadline)
                                        if !pd.phoneNumber.isEmpty {
                                            Text("Phone: \(pd.phoneNumber)")
                                                .font(.subheadline)
                                        }
                                        if !pd.linkedIn.isEmpty {
                                            Text("LinkedIn: \(pd.linkedIn)")
                                                .font(.subheadline)
                                        }
                                        if !pd.github.isEmpty {
                                            Text("GitHub: \(pd.github)")
                                                .font(.subheadline)
                                        }
                                        if !pd.website.isEmpty {
                                            Text("Website: \(pd.website)")
                                                .font(.subheadline)
                                        }
                                    }
                                } else {
                                    Text("Personal Details")
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { editorRoute = EditorRoute(kind: .section(.personalDetails)) }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await formViewModel.deletePersonalDetails() }
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                        case .experience:
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Experience (\(formViewModel.experiences.count))")
                                    .font(.headline)
                                if formViewModel.experiences.isEmpty == false {
                                    ForEach(formViewModel.experiences) { exp in
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(exp.role)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            Text(exp.company)
                                                .font(.footnote)
                                            Text("\(exp.startDateString) – \(exp.endDateString ?? "Present")")
                                                .font(.footnote)
                                                .foregroundColor(.secondary)
                                            if let desc = exp.description, desc.isEmpty == false {
                                                Text(desc)
                                                    .font(.footnote)
                                                    .lineLimit(2)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                        .contentShape(Rectangle())
                                        .onTapGesture { editorRoute = EditorRoute(kind: .editExperience(exp)) }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                Task { await formViewModel.deleteExperience(id: exp.id) }
                                            } label: { Label("Delete", systemImage: "trash") }
                                        }
                                    }
                                }
                            }
                        case .about:
                            Group {
                                if let about = formViewModel.about {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("About")
                                            .font(.headline)
                                        VStack(alignment: .leading, spacing: 2) {
                                            if !about.header.isEmpty {
                                                Text(about.header).font(.subheadline).fontWeight(.semibold)
                                            }
                                            if !about.subtitle.isEmpty {
                                                Text(about.subtitle).font(.footnote).fontWeight(.medium).foregroundColor(.secondary)
                                            }
                                            if !about.body.isEmpty {
                                                Text(about.body).font(.footnote).lineLimit(2)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                } else {
                                    Text("About")
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { 
                                if let about = formViewModel.about {
                                    editorRoute = EditorRoute(kind: .editAbout(about))
                                } else {
                                    editorRoute = EditorRoute(kind: .section(.about))
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await formViewModel.deleteAbout() }
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                        case .resume:
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Resume")
                                    .font(.headline)
                                if let resume = formViewModel.resume {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Image(systemName: "doc.fill")
                                                .foregroundColor(.blue)
                                            Text(resume.fileName)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                        Text("Uploaded: \(resume.uploadedAt, style: .date)")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 2)
                                } else {
                                    Text("No resume uploaded")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { editorRoute = EditorRoute(kind: .section(.resume)) }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await formViewModel.deleteResume() }
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                        case .skills:
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Skills")
                                    .font(.headline)
                                if let skills = formViewModel.skills?.skills, !skills.isEmpty {
                                    LazyVGrid(columns: [
                                        GridItem(.adaptive(minimum: 80), spacing: 8)
                                    ], spacing: 8) {
                                        ForEach(skills, id: \.self) { skill in
                                            Text(skill)
                                                .font(.footnote)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.blue.opacity(0.1))
                                                .foregroundColor(.blue)
                                                .cornerRadius(16)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                } else {
                                    Text("No skills added")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { editorRoute = EditorRoute(kind: .section(.skills)) }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await formViewModel.deleteSkills() }
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                        case .projects:
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Projects (\(formViewModel.projects.count))")
                                    .font(.headline)
                                if formViewModel.projects.isEmpty == false {
                                    ForEach(formViewModel.projects) { project in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(project.title)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            
                                            if let description = project.description, !description.isEmpty {
                                                Text(description)
                                                    .font(.footnote)
                                                    .lineLimit(2)
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
                                                Text(link)
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                                    .lineLimit(1)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                        .contentShape(Rectangle())
                                        .onTapGesture { editorRoute = EditorRoute(kind: .editProject(project)) }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                Task { await formViewModel.deleteProject(id: project.id) }
                                            } label: { Label("Delete", systemImage: "trash") }
                                        }
                                    }
                                } else {
                                    Text("No projects added")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .onMove(perform: formViewModel.reorderSections)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Details")
        .sheet(item: $editorRoute) { route in
            editorSheet(for: route)
        }
        .onAppear {
            if let uid = Auth.auth().currentUser?.uid {
                Task {
                    // Fetch all data first
                    await formViewModel.fetchPersonalDetails(userId: uid)
                    await formViewModel.fetchAbout(userId: uid)
                    await formViewModel.fetchExperiences(userId: uid)
                    await formViewModel.fetchResume(userId: uid)
                    await formViewModel.fetchSkills(userId: uid)
                    await formViewModel.fetchProjects(userId: uid)
                    
                    // Then apply the saved section order after all data is loaded
                    await formViewModel.fetchSectionOrder(userId: uid)
                }
            }
        }
    }

    @ViewBuilder
    private func editorSheet(for route: EditorRoute) -> some View {
        switch route.kind {
        case .section(let section):
            switch section {
            case .personalDetails:
                PersonalDetailsSheetView(onAdded: nil, initialData: formViewModel.personalDetails, isEditing: true)
                    .environmentObject(formViewModel)
            case .experience:
                ExperienceSheetView(onAdded: nil)
                    .environmentObject(formViewModel)
            case .projects:
                ProjectSheetView(onAdded: nil)
                    .environmentObject(formViewModel)
            case .skills:
                SkillsSheetView(onAdded: nil)
                    .environmentObject(formViewModel)
            case .resume:
                ResumeSheetView(onAdded: nil)
                    .environmentObject(formViewModel)
            case .about:
                AboutSheetView(onAdded: nil)
                    .environmentObject(formViewModel)
            }
        case .editExperience(let exp):
            ExperienceSheetView(onAdded: nil, initialData: exp, isEditing: true)
                .environmentObject(formViewModel)
        case .editAbout(let about):
            AboutSheetView(onAdded: nil, initialData: about, isEditing: true)
                .environmentObject(formViewModel)
        case .editProject(let project):
            ProjectSheetView(onAdded: nil, initialData: project, isEditing: true)
                .environmentObject(formViewModel)
        }
    }
}