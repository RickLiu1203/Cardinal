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
    @State private var showingEditorForSection: FormViewModel.SectionType? = nil
    var body: some View {
        List {
            AddSectionView()
            if formViewModel.selectedSections.isEmpty == false {
                Section {
                    ForEach(formViewModel.selectedSections, id: \.id) { section in
                        Button(action: { showingEditorForSection = section }) {
                            switch section {
                        case .personalDetails:
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
                                    }
                                }
                            }
                        case .textBlock:
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Text Blocks (\(formViewModel.textBlocks.count))")
                                    .font(.headline)
                                if formViewModel.textBlocks.isEmpty == false {
                                    ForEach(formViewModel.textBlocks) { block in
                                        VStack(alignment: .leading, spacing: 2) {
                                            if block.header.isEmpty == false {
                                                Text(block.header).font(.subheadline).fontWeight(.semibold)
                                            }
                                            if block.body.isEmpty == false {
                                                Text(block.body).font(.footnote).lineLimit(2)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
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
                                    }
                                } else {
                                    Text("No projects added")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                        default:
                            Text(section.title)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Details")
        .sheet(item: $showingEditorForSection) { section in
            editorSheet(for: section)
        }
        .onAppear {
            if let uid = Auth.auth().currentUser?.uid {
                Task {
                    await formViewModel.fetchPersonalDetails(userId: uid)
                    await formViewModel.fetchTextBlocks(userId: uid)
                    await formViewModel.fetchExperiences(userId: uid)
                    await formViewModel.fetchResume(userId: uid)
                    await formViewModel.fetchSkills(userId: uid)
                    await formViewModel.fetchProjects(userId: uid)
                }
            }
        }
    }

    @ViewBuilder
    private func editorSheet(for section: FormViewModel.SectionType) -> some View {
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
        case .textBlock:
            TextBlockSheetView(onAdded: nil)
                .environmentObject(formViewModel)
        }
    }
}