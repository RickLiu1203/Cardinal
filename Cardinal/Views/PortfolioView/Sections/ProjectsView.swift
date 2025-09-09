//
//  ProjectsView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI
import CoreText

struct ProjectsView: View {
    let projects: [PortfolioView.PresentableProject]

    var body: some View {
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

#Preview {
    List {
        ProjectsView(
            projects: [
                PortfolioView.PresentableProject(
                    id: "1",
                    title: "Weather App",
                    description: "A beautiful weather app built with SwiftUI featuring real-time weather data, 7-day forecasts, and location-based weather alerts.",
                    tools: ["SwiftUI", "CoreLocation", "WeatherKit", "Charts"],
                    link: "https://github.com/johndoe/weather-app"
                ),
                PortfolioView.PresentableProject(
                    id: "2",
                    title: "Task Manager Pro",
                    description: "A productivity app for managing daily tasks with cloud sync, collaboration features, and smart notifications.",
                    tools: ["UIKit", "Core Data", "CloudKit", "UserNotifications"],
                    link: "https://apps.apple.com/app/taskmanager-pro"
                ),
                PortfolioView.PresentableProject(
                    id: "3",
                    title: "Portfolio Website",
                    description: "Personal portfolio website showcasing projects and skills.",
                    tools: ["React", "TypeScript", "Next.js"],
                    link: "https://johndoe.dev"
                )
            ]
        )
    }
    .listStyle(.insetGrouped)
}

