//
//  ExperiencesView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI

struct ExperiencesView: View {
    let experiences: [PortfolioView.PresentableExperience]

    var body: some View {
        if !experiences.isEmpty {
            Section() {
                VStack(alignment: .leading, spacing: 12) {
                    Text("EXPERIENCES")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                    Text("a timeline of my career")
                        .font(.custom("MabryPro-Regular", size: 20))
                        .padding(.bottom, 16)
                    
                    ZStack(alignment: .topLeading) {
                        // Continuous timeline line
                        Rectangle()
                            .fill(Color("TextPrimary"))
                            .frame(width: 2)
                            .offset(x: 7) // Center on the circles (16px circle / 2 - 1px line / 2)
                        
                        // Experience entries with circles
                        VStack(spacing: 40) {
                            ForEach(Array(experiences.enumerated()), id: \.element.id) { index, exp in
                                HStack(alignment: .top, spacing: 16) {
                                    // Timeline circle
                                    Circle()
                                        .fill(Color.experiencesAccent)
                                        .frame(width: 16, height: 16)
                                        .overlay(
                                            Circle()
                                                .stroke(Color("TextPrimary"), lineWidth: 2)
                                        )
                                        .zIndex(1) // Ensure circles appear above the line
                                    
                                    VStack(alignment: .leading, spacing: 32) {
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text(exp.company)
                                                .font(.custom("MabryPro-Black", size: 20))

                                            Text(exp.role)
                                                .font(.custom("MabryPro-Medium", size: 18))
                                                .fixedSize(horizontal: false, vertical: true)
                                            
                                            
                                            Text(formatPeriod(startDateString: exp.startDateString, endDateString: exp.endDateString))
                                                .font(.custom("MabryPro-Regular", size: 16))
                                                .foregroundColor(Color.textSecondary)
                                        }
                                        if let desc = exp.description, !desc.isEmpty {
                                            Text(desc)
                                                .font(.custom("MabryPro-Regular", size: 16))
                                                .lineSpacing(6)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        
                                        if let skills = exp.skills, !skills.isEmpty {
                                            FlexWrap(spacing: 12) {
                                                ForEach(skills, id: \.self) { skill in
                                                    Text(skill)
                                                        .font(.custom("MabryPro-Bold", size: 14))
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 8)
                                                        .background(Color.experiencesAccent)
                                                        .foregroundColor(Color("TextPrimary"))
                                                        .border(Color("TextPrimary"), width: 1.5)
                                                        .lineLimit(1)
                                                        .fixedSize(horizontal: true, vertical: false)
                                                }
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 36)
                .padding(.vertical, 64)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.experiencesBackground)
            }
            PageDividerView()
        }

    }

    private func formatPeriod(startDateString: String?, endDateString: String?) -> String {
        let start = parseToMonthYear(startDateString) ?? ""
        let end = endDateString != nil ? (parseToMonthYear(endDateString) ?? "") : "Present"
        return "\(start) – \(end)"
    }
    
    private func parseToMonthYear(_ dateString: String?) -> String? {
        guard let dateString = dateString, !dateString.isEmpty else { return nil }
        let trimmed = dateString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Output formatter (short month + year)
        let out = DateFormatter()
        out.locale = Locale(identifier: "en_US_POSIX")
        out.dateFormat = "MMM yyyy"

        // Try a set of common input formats we see in storage
        let patterns = [
            "d MMMM yyyy 'at' HH:mm:ss 'UTC'XXX", // 8 September 2025 at 20:50:04 UTC-4
            "d MMMM yyyy",                        // 8 September 2025
            "MMM d, yyyy",                        // Sep 9, 2024
            "MMMM d, yyyy",                       // September 9, 2024
            "yyyy-MM-dd"                          // 2025-09-08
        ]

        for pattern in patterns {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = pattern
            if let date = f.date(from: trimmed) {
                return out.string(from: date)
            }
        }

        // If it's already in the desired format, return it as-is
        let alreadyShort = DateFormatter()
        alreadyShort.locale = Locale(identifier: "en_US_POSIX")
        alreadyShort.dateFormat = "MMM yyyy"
        if alreadyShort.date(from: trimmed) != nil {
            return trimmed
        }

        return trimmed
    }
}

#Preview {
    List {
        ExperiencesView(
            experiences: [
                PortfolioView.PresentableExperience(
                    id: "1",
                    company: "Tech Corp",
                    role: "Senior iOS Developer",
                    startDateString: "Jan 2023",
                    endDateString: nil,
                    description: "Leading iOS development team and architecting scalable mobile applications using SwiftUI and UIKit.",
                    skills: ["Swift", "SwiftUI", "UIKit", "iOS", "Xcode"]
                ),
                PortfolioView.PresentableExperience(
                    id: "2",
                    company: "StartupXYZ",
                    role: "Junior Developer",
                    startDateString: "Jun 2022",
                    endDateString: "Dec 2022",
                    description: "Built web applications using React and Node.js, collaborated with design team on user experience improvements.",
                    skills: ["React", "Node.js", "JavaScript", "HTML", "CSS"]
                )
            ]
        )
    }
    .listStyle(.insetGrouped)
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

