//
//  PortfolioModel.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import Foundation

struct PersonalDetails: Codable, Equatable {
    let firstName: String
    let lastName: String
    let subtitle: String
    let email: String
    let linkedIn: String
    let phoneNumber: String
    let github: String
    let website: String
}

struct AboutBlock: Codable, Equatable {
    let header: String
    let subtitle: String
    let body: String
}

struct ExperienceItem: Codable, Equatable, Identifiable {
    let id: String
    let company: String
    let role: String
    // Formatted date strings coming from the Cloud Function (may be null)
    let startDate: String?
    let endDate: String?
    let description: String?
    let skills: [String]?
}

struct ResumeItem: Codable, Equatable {
    let fileName: String
    let downloadURL: String
    let uploadedAt: String // formatted date string from Cloud Function
}

struct ProjectItem: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let tools: [String]
    let link: String?
}

struct PortfolioResponse: Codable, Equatable {
    let firstName: String
    let lastName: String
    let subtitle: String
    let email: String
    let linkedIn: String
    let phoneNumber: String
    let github: String
    let website: String
    let about: AboutBlock?
    let experiences: [ExperienceItem]?
    let resume: ResumeItem?
    let skills: [String]?
    let projects: [ProjectItem]?
    let sectionOrder: [String]?
}

enum PortfolioPayloadParser {
    static func from(url: URL) -> PersonalDetails? {
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        func q(_ name: String) -> String { comps?.queryItems?.first(where: { $0.name == name })?.value ?? "" }
        let first = q("fn")
        let last = q("ln")
        let subtitle = q("st")
        let email = q("em")
        let li = q("li")
        let phone = q("ph")
        let github = q("gh")
        let website = q("ws")
        if [first, last, email, li, phone, github, website].contains(where: { !$0.isEmpty }) {
            return PersonalDetails(firstName: first, lastName: last, subtitle: subtitle, email: email, linkedIn: li, phoneNumber: phone, github: github, website: website)
        }
        return nil
    }

    static func from(payload: [String: String]) -> PersonalDetails? {
        let first = payload["firstName"] ?? payload["fn"] ?? ""
        let last = payload["lastName"] ?? payload["ln"] ?? ""
        let subtitle = payload["subtitle"] ?? payload["st"] ?? ""
        let email = payload["email"] ?? payload["em"] ?? ""
        let li = payload["linkedIn"] ?? payload["li"] ?? ""
        let phone = payload["phoneNumber"] ?? payload["ph"] ?? ""
        let github = payload["github"] ?? payload["gh"] ?? ""
        let website = payload["website"] ?? payload["ws"] ?? ""
        if [first, last, email, li, phone, github, website].contains(where: { !$0.isEmpty }) {
            return PersonalDetails(firstName: first, lastName: last, subtitle: subtitle, email: email, linkedIn: li, phoneNumber: phone, github: github, website: website)
        }
        return nil
    }
}

