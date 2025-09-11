//
//  AboutView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI

struct AboutView: View {
    let about: PortfolioView.PresentableAbout?
    let resume: PortfolioView.PresentableResume?
    let onViewTapped: ((URL) -> Void)?
    @State private var isResumeButtonPressed = false

    var body: some View {
        if let about = about {
            Section() {
                VStack(alignment: .leading, spacing: 32) {
                    if !about.header.isEmpty || !about.subtitle.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            if !about.header.isEmpty {
                                Text(about.header)
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                            }
                            if !about.subtitle.isEmpty {
                                Text(about.subtitle)
                                    .font(.custom("MabryPro-Regular", size: 20))
                            }
                        }
                    }
                    if !about.body.isEmpty {
                        Text(.init(about.body))
                            .font(.custom("MabryPro-Light", size: 18))
                            .lineSpacing(8)
                    }
                    
                    if let resume = resume, let onViewTapped = onViewTapped {
                        Text("check out my resume!")
                            .font(.custom("MabryPro-Bold", size: 20))
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .shadow(color: isResumeButtonPressed ? .clear : .black, radius: 0, x: isResumeButtonPressed ? 0 : 4, y: isResumeButtonPressed ? 0 : 4)
                                    .foregroundColor(Color.aboutAccent)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(.black, lineWidth: 2)
                            )
                            .offset(x: isResumeButtonPressed ? 4 : 0, y: isResumeButtonPressed ? 4 : 0)
                            .animation(.easeInOut(duration: 0.05), value: isResumeButtonPressed)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.05)) {
                                    isResumeButtonPressed = true
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.easeInOut(duration: 0.05)) {
                                        isResumeButtonPressed = false
                                    }
                                    
                                    if let url = URL(string: resume.downloadURL) {
                                        onViewTapped(url)
                                    }
                                }
                            }
                    }
                }
                .padding(.horizontal, 36)
                .padding(.vertical, 64)
                PageDividerView()
            }
            .background(Color.aboutAccent.opacity(0.1))
        }
    }
}

#Preview {
    List {
        AboutView(
            about: PortfolioView.PresentableAbout(
                header: "Highlights",
                subtitle: "Software Developer",
                body: "I'm a **passionate software developer** with experience in iOS development and web technologies. I love creating **beautiful and functional applications**."
            ),
            resume: PortfolioView.PresentableResume(
                fileName: "John_Doe_Resume.pdf",
                downloadURL: "https://example.com/resume.pdf",
                uploadedAt: "Dec 15, 2024"
            ),
            onViewTapped: { url in
                print("Would open: \(url)")
            }
        )
    }
    .listStyle(.insetGrouped)
}
