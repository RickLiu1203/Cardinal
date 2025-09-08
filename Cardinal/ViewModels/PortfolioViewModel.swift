//
//  PortfolioViewModel.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import Foundation

final class PortfolioViewModel: ObservableObject {
    @Published var personalDetails: PersonalDetails?
    @Published var textBlocks: [TextBlock] = []
    @Published var experiences: [ExperienceItem] = []
    @Published var resume: ResumeItem?
    @Published var skills: [String] = []
    @Published var projects: [ProjectItem] = []

    // Returns a struct that PortfolioView can accept directly as an override
    var presentableDetails: (firstName: String, lastName: String, email: String, linkedIn: String)? {
        guard let pd = personalDetails else { return nil }
        return (pd.firstName, pd.lastName, pd.email, pd.linkedIn)
    }

    // App Clip-friendly: parse URL query items to populate data
    func apply(url: URL) {
        // Prefer id=USER_ID for Firestore hydration when available
        if let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "id" })?.value, id.isEmpty == false {
            Task { await fetchPortfolioViaHTTPS(userId: id) }
            return
        }
        // Fallback to direct payload query params (fn/ln/em/li)
        personalDetails = PortfolioPayloadParser.from(url: url)
    }

    // Convenience for injecting a prebuilt payload (e.g., from NSUserActivity userInfo)
    func load(from payload: [String: String]) {
        personalDetails = PortfolioPayloadParser.from(payload: payload)
    }

    // MARK: - HTTPS hydration by user id (App Clip friendly)
    // Uses Cloud Function endpoint to fetch portfolio data
    func fetchPortfolioViaHTTPS(userId: String) async {
        guard var comps = URLComponents(string: "https://us-central1-cardinalapp-4279c.cloudfunctions.net/getPortfolio") else { return }
        comps.queryItems = [URLQueryItem(name: "id", value: userId)]
        guard let url = comps.url else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return }
            let decoded = try JSONDecoder().decode(PortfolioResponse.self, from: data)
            await MainActor.run {
                self.personalDetails = PersonalDetails(firstName: decoded.firstName,
                                                       lastName: decoded.lastName,
                                                       email: decoded.email,
                                                       linkedIn: decoded.linkedIn,
                                                       phoneNumber: decoded.phoneNumber,
                                                       github: decoded.github,
                                                       website: decoded.website)
                self.textBlocks = decoded.textBlocks ?? []
                // Sort experiences by endDate desc; nils last; fallback to startDate desc
                let items = decoded.experiences ?? []
                self.experiences = items.sorted { a, b in
                    switch (a.endDate, b.endDate) {
                    case let (la?, lb?): return la > lb
                    case (nil, _?): return false
                    case (_?, nil): return true
                    default: return (a.startDate ?? "") > (b.startDate ?? "")
                    }
                }
                self.resume = decoded.resume
                self.skills = decoded.skills ?? []
                self.projects = decoded.projects ?? []
            }
        } catch {
            // No-op for clip; optionally capture to analytics
        }
    }
}

