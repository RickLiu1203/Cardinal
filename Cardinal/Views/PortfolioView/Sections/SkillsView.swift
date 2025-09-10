//
//  SkillsView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI

extension Color {
    static let skillsAccent = Color(red: 1.0, green: 0.855, blue: 0.376)
    static let skillsBackground = Color.skillsAccent.opacity(0.05)
}

struct SkillsView: View {
    let skills: PortfolioView.PresentableSkills

    var body: some View {
        Section() {
            SkillsMarquee(tokens: interleavedTokens(from: skills.skills))
            .padding(.top, 36)
            .padding(.bottom, 72)
            .background(Color.skillsBackground)
            PageDividerView()
        }
    }
}

private enum Token: Hashable, Identifiable {
    case skill(String, Int) // Include position for unique ID
    case symbol(String, Int) // Include position for unique ID

    var id: String {
        switch self {
        case .skill(let text, let position): return "skill-\(text)-\(position)"
        case .symbol(let name, let position): return "symbol-\(name)-\(position)"
        }
    }
}

private extension SkillsView {
    func interleavedTokens(from skills: [String]) -> [Token] {
        guard !skills.isEmpty else { return [] }
        let symbols = ["seal.fill", "diamond.fill", "star.fill", "heart.fill", "hexagon.fill", "circle.fill"]
        var result: [Token] = []
        var tokenPosition = 0
        
        for (index, skill) in skills.enumerated() {
            result.append(.skill(skill, tokenPosition))
            tokenPosition += 1
            if index < skills.count - 1 {
                let symbol = symbols[index % symbols.count]
                result.append(.symbol(symbol, tokenPosition))
                tokenPosition += 1
            }
        }
        // Add a trailing symbol to separate when looping
        if let first = skills.first {
            let symbol = symbols[skills.count % symbols.count]
            result.append(.symbol(symbol, tokenPosition))
            tokenPosition += 1
            result.append(.skill(first, tokenPosition)) // Leads into first for seamless loop perception
        }
        return result
    }
}

private struct SkillsMarquee: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let tokens: [Token]

    @State private var contentWidth: CGFloat = 0
    @State private var baselineDate: Date = Date()
    @State private var accumulatedBeforePause: TimeInterval = 0
    @State private var pauseDate: Date? = nil

    private let spacing: CGFloat = 16
    private let speedPointsPerSecond: CGFloat = 40 // Adjust for desired speed

    var body: some View {
        Group {
            if reduceMotion {
                GeometryReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: spacing) {
                            rowContent
                        }
                        .padding(.horizontal)
                        .frame(width: proxy.size.width, alignment: .leading)
                        .frame(height: 48)
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                }
            } else {
                TimelineView(.animation) { context in
                    let cycleWidth = max(contentWidth, 1)
                    let runningElapsed = pauseDate.map { max(0, $0.timeIntervalSince(baselineDate)) } ?? max(0, context.date.timeIntervalSince(baselineDate))
                    let totalElapsed = accumulatedBeforePause + runningElapsed
                    let traveled = CGFloat(totalElapsed) * speedPointsPerSecond
                    let offset = -traveled.truncatingRemainder(dividingBy: cycleWidth)

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            HStack(spacing: spacing) { rowContent }
                                .background(widthReader)
                                .offset(x: offset)

                            HStack(spacing: spacing) { rowContent }
                                .offset(x: offset + cycleWidth)
                        }
                        .frame(width: proxy.size.width, height: 48, alignment: .leading)
                        .frame(maxHeight: .infinity, alignment: .center)
                        .contentShape(Rectangle())
                    }
                }
                .onAppear {
                    if let pauseDate {
                        accumulatedBeforePause += max(0, pauseDate.timeIntervalSince(baselineDate))
                        self.pauseDate = nil
                    }
                    baselineDate = Date()
                }
                .onDisappear {
                    pauseDate = Date()
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var rowContent: some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(tokens) { token in
                switch token {
                case .skill(let text, _):
                    Text(text)
                        .font(.custom("MabryPro-BoldItalic", size: 28))
                        .foregroundColor(Color("TextPrimary"))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .layoutPriority(1)
                        .padding(.horizontal, 4)
                case .symbol(let name, _):
                    Image(systemName: name)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.skillsAccent)
                }
            }
        }
    }

    private var widthReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(key: ContentWidthKey.self, value: proxy.size.width)
        }
        .onPreferenceChange(ContentWidthKey.self) { newWidth in
            if abs(newWidth - contentWidth) > 0.5 {
                contentWidth = newWidth
            }
        }
    }
}

private struct ContentWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    List {
        SkillsView(
            skills: PortfolioView.PresentableSkills(
                skills: ["Swift", "SwiftUI", "UIKit", "React", "Node.js", "Firebase", "Git", "Xcode", "JavaScript", "Python", "Core Data", "CloudKit"]
            )
        )
    }
    .listStyle(.insetGrouped)
}

