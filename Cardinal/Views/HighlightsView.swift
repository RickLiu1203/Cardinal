//
//  HighlightsView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-07-24.
//

import SwiftUI
import Contacts
import ContactsUI

private let bulletPoints = RickData.bulletPoints
private let contactInfo = RickData.contactInfo

private let h1 = FontSize.h1
private let subtitle = FontSize.subtitle
private let body1 = FontSize.body1

struct HighlightsView: View {
    @State private var showContactAlert = false
    
    private func splitFirstWord(_ text: String) -> (first: String, rest: String?) {
        let components = text.split(separator: " ", maxSplits: 1)
        let firstWord = String(components[0])
        let restOfText = components.count > 1 ? String(components[1]) : nil
        return (firstWord, restOfText)
    }
    
    private func addContactInfo() {
        let contact = CNMutableContact()
        contact.givenName = contactInfo.firstName
        contact.familyName = contactInfo.lastName
        contact.emailAddresses = [CNLabeledValue(label: CNLabelWork, value: contactInfo.emailAddress as NSString)]
        contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: contactInfo.phoneNumber))]
        
        let controller = CNContactViewController(for: contact)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            let navController = UINavigationController(rootViewController: controller)
            rootVC.present(navController, animated: true)
        }
    }
    
    var body: some View {
        VStack (alignment: .leading, spacing: 48){
            // title
            VStack (alignment: .leading, spacing: 8){
                Text("HIGHLIGHTS")
                    .font(.system(size: h1, weight: .bold, design: .rounded))
                Text("what i'm most proud of")
                    .font(.mabryPro(size: subtitle))
            }
            
            // bullet points
            VStack(alignment: .leading, spacing: 12){
                ForEach(bulletPoints, id: \.self){ bulletPoint in
                    HStack(alignment: .top, spacing: 12){
                        Text("•")
                            .font(.system(size: 16, design: .rounded))
                            .lineSpacing(32 - 16)
                        let parts = splitFirstWord(bulletPoint)
                        (Text(parts.first)
                            .font(.mabryPro(size: body1, weight: .bold)) +
                        Text(parts.rest != nil ? " " + parts.rest! : "")
                            .font(.mabryPro(size: body1, weight: .light)))
                            .lineSpacing(32 - body1)
                    }
                }
            }

            VStack(spacing: 32){
            // check out resume
            Button(action: {
                
            }) {
                Text("check out my resume!")
                    .font(.mabryPro(size: body1))
                    .foregroundColor(.black)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
            }
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .shadow(color: .black, radius: 0, x: 4, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.black, lineWidth: 2)
            )

            // add contact info
            Button(action: {
                addContactInfo()
            }) {
                Text("add my contact info!")
                    .font(.mabryPro(size: body1))
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
            }
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .shadow(color: .black, radius: 0, x: 4, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.black, lineWidth: 2)
            )
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .padding(.horizontal, 36)
        .padding(.vertical, 64)
        .foregroundColor(.black)
    }
}
