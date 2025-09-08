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
                                    if pd.linkedIn.isEmpty == false {
                                        Text("LinkedIn: \(pd.linkedIn)")
                                            .font(.subheadline)
                                    }
                                }
                            } else {
                                Text("Personal Details")
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
                Task { await formViewModel.fetchPersonalDetails(userId: uid) }
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
        case .list:
            ListSheetView(onAdded: nil)
                .environmentObject(formViewModel)
        }
    }
}