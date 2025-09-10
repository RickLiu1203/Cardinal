//
//  ProjectsView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI
import CoreText

extension Color {
    static let portfolioAccent = Color(red: 1.0, green: 0.76, blue: 0.984)
    static let portfolioBackground = Color.portfolioAccent.opacity(0.1)
}

struct ProjectsView: View {
    let projects: [PortfolioView.PresentableProject]

    var body: some View {
        if !projects.isEmpty {
            Section() {
                VStack(alignment: .leading, spacing: 12) {
                    Text("PROJECTS")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                    Text("showcase of some cool work")
                        .font(.custom("MabryPro-Regular", size: 20))
                        .padding(.bottom, 16)

                ForEach(projects.reversed(), id: \.id) { project in
                    ProjectCard(project: project)
                        .padding(.bottom, 16)
                }
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 64)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.portfolioBackground)
            }
            PageDividerView()
        }
    }
}

private struct ProjectCard: View {
    let project: PortfolioView.PresentableProject
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(project.title)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .kerning(1)

            if let description = project.description, !description.isEmpty {
                Text(description)
                    .font(.custom("MabryPro-Regular", size: 16))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if !project.tools.isEmpty {
                FlexWrap(spacing: 12) {
                    ForEach(project.tools, id: \.self) { tool in
                        Text(tool)
                            .font(.custom("MabryPro-Bold", size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.portfolioAccent)
                            .foregroundColor(Color("TextPrimary"))
                            .border(Color("TextPrimary"), width: 1.5)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }

            if let link = project.link, !link.isEmpty {
                Button(action: {
                    if let url = URL(string: link) {
                        AnalyticsManager.shared.logEvent(action: "open_project_link", meta: ["projectId": project.id, "url": url.absoluteString])
                        openURL(url)
                    }
                }) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 24))
                }
                .foregroundColor(Color("TextPrimary"))
            }
        }
        .padding(36)
        .frame(minHeight: 360, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("BackgroundPrimary"))
                .shadow(color: .black, radius: 0, x: 4, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.black, lineWidth: 2)
        )
    }
}

// FlexWrap layout that mimics CSS flexbox wrap behavior
private struct FlexWrapLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let availableWidth = proposal.width ?? .infinity
        var currentRowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxRowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentRowWidth + subviewSize.width > availableWidth && currentRowWidth > 0 {
                // Start new row
                totalHeight += maxRowHeight + spacing
                currentRowWidth = subviewSize.width + spacing
                maxRowHeight = subviewSize.height
            } else {
                // Add to current row
                currentRowWidth += subviewSize.width + spacing
                maxRowHeight = max(maxRowHeight, subviewSize.height)
            }
        }
        
        totalHeight += maxRowHeight
        return CGSize(width: availableWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var maxRowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentX + subviewSize.width > bounds.maxX && currentX > bounds.minX {
                // Start new row
                currentX = bounds.minX
                currentY += maxRowHeight + spacing
                maxRowHeight = 0
            }
            
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += subviewSize.width + spacing
            maxRowHeight = max(maxRowHeight, subviewSize.height)
        }
    }
}

// Convenience view wrapper for FlexWrap Layout
private struct FlexWrap<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content
    
    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        FlexWrapLayout(spacing: spacing) {
            content
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

