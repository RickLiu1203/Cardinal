import SwiftUI

private let h2 = FontSize.h2

struct SkillsTickerView: View {
    let skills = ["Swift", "SwiftUI", "Combine", "Firebase", "GraphQL", "Git", "CI/CD", "UX Design"]
    let speed: CGFloat = 100
    @State private var totalTextWidth: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let screenWidth = geo.size.width

            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let distance = CGFloat(time * speed).truncatingRemainder(dividingBy: totalTextWidth)

                Canvas { context, size in
                    var x = -distance

                    while x < screenWidth {
                        for skill in skills {
                            let text = Text(skill)
                                .font(.mabryPro(size: h2, italic: true))
                            let resolved = context.resolve(text)
                            context.draw(resolved, at: CGPoint(x: x + resolved.measure(in: size).width / 2, y: size.height / 2))
                            x += resolved.measure(in: size).width + 40 // spacing between items
                        }
                    }
                }
                .frame(height: 40)
            }
            .onAppear {
                // Estimate width only once
                let font = UIFont(name: "MabryPro-Italic", size: h2) ?? UIFont.systemFont(ofSize: h2)
                totalTextWidth = skills.reduce(0) { result, skill in
                    let size = (skill as NSString).size(withAttributes: [.font: font])
                    return result + size.width + 40 // include spacing
                }
            }
            .padding(.vertical, 36)
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.black),
                alignment: .top
            )
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.black),
                alignment: .bottom
            )
        }
        .frame(height: 120)
    }
}
