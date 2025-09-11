import SwiftUI

struct ReusableLogRowView: View {
    let actionType: String
    let formattedTime: String
    let userName: String
    let link: String?
    let shouldTruncate: Bool
    
    private var iconData: (String, Color) {
        switch actionType {
        case "open_github": return ("chevron.left.slash.chevron.right", .homeAccent)
        case "open_linkedin": return ("link", .blue)
        case "open_website": return ("globe", .blue)
        case "view_resume": return ("doc.text.fill", .orange)
        case "open_project_link": return ("arrow.up.right.square", .purple)
        case "add_contact": return ("person.crop.circle.badge.plus", .green)
        case "add_message": return ("bubble.left.fill", .mint)
        case "page_view": return ("eye.fill", .gray)
        case "notification_sent": return ("bell.fill", .red)
        default: return ("clock", .gray)
        }
    }
    
    private var readableAction: String {
        switch actionType {
        case "open_github": return "Viewed Your GitHub"
        case "open_linkedin": return "Viewed Your LinkedIn"
        case "open_website": return "Viewed Your Website"
        case "view_resume": return "Viewed Your Resume"
        case "open_project_link": return "Viewed a Project"
        case "add_contact": return "Added Your Contact"
        case "add_message": return "Added a Message"
        case "page_view": return "Opened Your AppClip"
        case "notification_sent": return "Received Notification"
        default: return actionType.replacingOccurrences(of: "_", with: " ")
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            let (symbol, tint) = iconData
            Circle()
                .fill(tint.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay {
                    Circle()
                        .stroke(Color.black, lineWidth: 1)
                }
                .overlay {
                    Image(systemName: symbol)
                        .foregroundColor(.black)
                        .font(.system(size: 14))
                }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                Text(userName.uppercased())
                    .font(.custom("MabryPro-Black", size: 16))
                    .foregroundColor(Color("TextPrimary"))
                Text("•")
                    .font(.custom("MabryPro-Black", size: 16))
                    .foregroundColor(Color("TextPrimary"))
                Text(readableAction)
                    .font(.custom("MabryPro-Medium", size: 16))
                    .foregroundColor(Color("TextPrimary"))
                }
                .lineLimit(shouldTruncate ? 1 : nil)
                .truncationMode(.tail)
                Text("\(formattedTime)")
                    .font(.custom("MabryPro-Regular", size: 14))
                    .foregroundColor(Color.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    VStack(spacing: 16) {
        ReusableLogRowView(
            actionType: "open_github",
            formattedTime: "Dec 8, 2024 14:30",
            userName: "John Doe",
            link: "https://github.com/user/repository",
            shouldTruncate: true
        )
        
        ReusableLogRowView(
            actionType: "add_message",
            formattedTime: "Dec 8, 2024 14:25",
            userName: "Jane Smith",
            link: nil,
            shouldTruncate: false
        )
        
        ReusableLogRowView(
            actionType: "view_resume",
            formattedTime: "Dec 8, 2024 14:20",
            userName: "Mike Johnson with a very long name that should truncate",
            link: "https://example.com/resume.pdf",
            shouldTruncate: true
        )
    }
    .padding()
    .background(Color("BackgroundPrimary"))
}
