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
    let email: String
    let linkedIn: String
}

enum PortfolioPayloadParser {
    static func from(url: URL) -> PersonalDetails? {
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        func q(_ name: String) -> String { comps?.queryItems?.first(where: { $0.name == name })?.value ?? "" }
        let first = q("fn")
        let last = q("ln")
        let email = q("em")
        let li = q("li")
        if [first, last, email, li].contains(where: { !$0.isEmpty }) {
            return PersonalDetails(firstName: first, lastName: last, email: email, linkedIn: li)
        }
        return nil
    }

    static func from(payload: [String: String]) -> PersonalDetails? {
        let first = payload["firstName"] ?? payload["fn"] ?? ""
        let last = payload["lastName"] ?? payload["ln"] ?? ""
        let email = payload["email"] ?? payload["em"] ?? ""
        let li = payload["linkedIn"] ?? payload["li"] ?? ""
        if [first, last, email, li].contains(where: { !$0.isEmpty }) {
            return PersonalDetails(firstName: first, lastName: last, email: email, linkedIn: li)
        }
        return nil
    }
}

