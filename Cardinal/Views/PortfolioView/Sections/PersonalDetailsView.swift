//
//  PersonalDetailsView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI
import Contacts
import ContactsUI

struct PersonalDetailsView: View {
    let personalDetails: PortfolioView.PresentablePersonalDetails
    @Environment(\.openURL) private var openURL
    @State private var contactDelegate = ContactDelegate()
    @State private var isButtonPressed = false

    var body: some View {
        Section() {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(personalDetails.firstName) \(personalDetails.lastName)")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(Color("TextPrimary"))
                if !personalDetails.subtitle.isEmpty {
                    Text(personalDetails.subtitle)
                        .font(.custom("MabryPro-Regular", size: 20))
                        .foregroundColor(Color("TextPrimary"))
                }
                
                if !personalDetails.linkedIn.isEmpty || !personalDetails.github.isEmpty || !personalDetails.website.isEmpty {
                    HStack(spacing: 16) {
                        if !personalDetails.linkedIn.isEmpty {
                            Button(action: {
                                if let url = URL(string: personalDetails.linkedIn.trimmingCharacters(in: .whitespacesAndNewlines)) {
                                    AnalyticsManager.shared.logEvent(action: "open_linkedin", meta: ["url": url.absoluteString])
                                    openURL(url)
                                }
                            }) {
                                Text("LinkedIn")
                                    .font(.custom("MabryPro-Regular", size: 18))
                                    .underline()
                                    .foregroundColor(Color("TextPrimary"))
                            }
                        }
                        if !personalDetails.github.isEmpty {
                            Button(action: {
                                if let url = URL(string: personalDetails.github.trimmingCharacters(in: .whitespacesAndNewlines)) {
                                    AnalyticsManager.shared.logEvent(action: "open_github", meta: ["url": url.absoluteString])
                                    openURL(url)
                                }
                            }) {
                                Text("GitHub")
                                    .font(.custom("MabryPro-Regular", size: 18))
                                    .underline()
                                    .foregroundColor(Color("TextPrimary"))
                            }
                        }
                        if !personalDetails.website.isEmpty {
                            Button(action: {
                                if let url = URL(string: personalDetails.website.trimmingCharacters(in: .whitespacesAndNewlines)) {
                                    AnalyticsManager.shared.logEvent(action: "open_website", meta: ["url": url.absoluteString])
                                    openURL(url)
                                }
                            }) {
                                Text("Website")
                                    .font(.custom("MabryPro-Regular", size: 18))
                                    .underline()
                                    .foregroundColor(Color("TextPrimary"))
                            }
                        }
                    }
                    .padding(.top, 4)
                }

                 // Add contact button
                Text("add my contact!")
                    .font(.custom("MabryPro-Bold", size: 20))
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .shadow(color: isButtonPressed ? .clear : .black, radius: 0, x: isButtonPressed ? 0 : 4, y: isButtonPressed ? 0 : 4)
                            .foregroundColor(Color("BackgroundPrimary"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.black, lineWidth: 2)
                    )
                    .offset(x: isButtonPressed ? 4 : 0, y: isButtonPressed ? 4 : 0)
                    .animation(.easeInOut(duration: 0.1), value: isButtonPressed)
                    .padding(.top, 8)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.05)) {
                            isButtonPressed = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.05)) {
                                isButtonPressed = false
                            }
                            
                            AnalyticsManager.shared.logEvent(action: "add_contact")
                            addToContacts()
                        }
                    }

            }   
            .padding(.horizontal, 36)
            .padding(.top, 36)
            .padding(.bottom, 48)
            PageDividerView()
        }
    }
    
    private func addToContacts() {
        let contact = CNMutableContact()
        
        // Set name
        contact.givenName = personalDetails.firstName
        contact.familyName = personalDetails.lastName
        
        // Set email if available
        if !personalDetails.email.isEmpty {
            let email = CNLabeledValue(label: CNLabelWork, value: personalDetails.email as NSString)
            contact.emailAddresses = [email]
        }
        
        // Set phone number if available
        if !personalDetails.phoneNumber.isEmpty {
            let phoneNumber = CNPhoneNumber(stringValue: personalDetails.phoneNumber)
            let phone = CNLabeledValue(label: CNLabelPhoneNumberMobile, value: phoneNumber)
            contact.phoneNumbers = [phone]
        }
        
        // Set URLs
        var urlAddresses: [CNLabeledValue<NSString>] = []
        if !personalDetails.website.isEmpty {
            urlAddresses.append(CNLabeledValue(label: "Website", value: personalDetails.website.trimmingCharacters(in: .whitespacesAndNewlines) as NSString))
        }
        if !personalDetails.linkedIn.isEmpty {
            urlAddresses.append(CNLabeledValue(label: "LinkedIn", value: personalDetails.linkedIn.trimmingCharacters(in: .whitespacesAndNewlines) as NSString))
        }
        if !personalDetails.github.isEmpty {
            urlAddresses.append(CNLabeledValue(label: "GitHub", value: personalDetails.github.trimmingCharacters(in: .whitespacesAndNewlines) as NSString))
        }
        contact.urlAddresses = urlAddresses
        
        // Set organization if subtitle is available
        if !personalDetails.subtitle.isEmpty {
            contact.organizationName = personalDetails.subtitle
        }
        
        // Present the contact view controller for adding new contact
        let contactViewController = CNContactViewController(forNewContact: contact)
        contactViewController.delegate = contactDelegate
        
        // Add dismiss button
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: contactDelegate, action: #selector(ContactDelegate.dismissContactView))
        contactViewController.navigationItem.rightBarButtonItem = doneButton
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            let navController = UINavigationController(rootViewController: contactViewController)
            contactDelegate.navigationController = navController
            rootViewController.present(navController, animated: true) {
                // Dismiss keyboard after presentation to prevent auto-focus
                DispatchQueue.main.async {
                    navController.view.endEditing(true)
                }
            }
        }
    }
}

// Delegate to handle contact view controller
class ContactDelegate: NSObject, CNContactViewControllerDelegate {
    weak var navigationController: UINavigationController?
    
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        // This handles both "Done" (contact saved) and "Cancel" actions
        viewController.dismiss(animated: true)
    }
    
    @objc func dismissContactView() {
        // Additional dismiss button in case user wants to close without adding
        navigationController?.dismiss(animated: true)
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

