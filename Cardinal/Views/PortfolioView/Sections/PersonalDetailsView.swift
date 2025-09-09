//
//  PersonalDetailsView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI

struct PersonalDetailsView: View {
    let personalDetails: PortfolioView.PresentablePersonalDetails

    var body: some View {
        Section() {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(personalDetails.firstName) \(personalDetails.lastName)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Color("TextPrimary"))
                if !personalDetails.subtitle.isEmpty {
                    Text(personalDetails.subtitle)
                        .font(.custom("MabryPro-Regular", size: 18))
                        .foregroundColor(Color("TextPrimary"))
                }
                Text(personalDetails.email)
                    .font(.custom("MabryPro-Regular", size: 18))
                    .foregroundColor(Color("TextPrimary"))
                if !personalDetails.phoneNumber.isEmpty {
                    Text(personalDetails.phoneNumber)
                        .font(.custom("MabryPro-Regular", size: 18))
                            .foregroundColor(Color("TextPrimary"))
                }
                if !personalDetails.linkedIn.isEmpty || !personalDetails.github.isEmpty || !personalDetails.website.isEmpty {
                    HStack(spacing: 16) {
                        if !personalDetails.linkedIn.isEmpty {
                            Link(destination: URL(string: personalDetails.linkedIn) ?? URL(string: "https://linkedin.com")!) {
                                    Text("LinkedIn")
                                        .font(.custom("MabryPro-Regular", size: 16))
                                        .underline()
                                .foregroundColor(Color("TextPrimary"))
                            }
                        }
                        if !personalDetails.github.isEmpty {
                            Link(destination: URL(string: personalDetails.github) ?? URL(string: "https://github.com")!) {
                                    Text("GitHub")
                                        .font(.custom("MabryPro-Regular", size: 16))
                                        .underline()
                                .foregroundColor(Color("TextPrimary"))
                            }
                        }
                        if !personalDetails.website.isEmpty {
                            Link(destination: URL(string: personalDetails.website) ?? URL(string: "https://example.com")!) {
                                    Text("Website")
                                        .font(.custom("MabryPro-Regular", size: 16))
                                        .underline()
                                .foregroundColor(Color("TextPrimary"))
                            }
                        }
                    }
                    .padding(.top, 4)
                }

            }   
            .padding(36)
            PageDividerView()
        }
    }
}

#Preview {
    List {
        PersonalDetailsView(
            personalDetails: PortfolioView.PresentablePersonalDetails(
                firstName: "John",
                lastName: "Doe",
                subtitle: "Computer Engineering @ UWaterloo",
                email: "john.doe@example.com",
                linkedIn: "https://linkedin.com/in/johndoe",
                phoneNumber: "+1 (555) 123-4567",
                github: "https://github.com/johndoe",
                website: "https://johndoe.dev"
            )
        )
    }
    .listStyle(.insetGrouped)
}

