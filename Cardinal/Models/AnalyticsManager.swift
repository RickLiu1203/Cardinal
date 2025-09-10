//
//  AnalyticsManager.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-10.
//

import Foundation
import SwiftUI

final class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()

    @Published var stats: AnalyticsStats? = nil
    @Published var events: [AnalyticsEvent] = []

    // Owner of the portfolio being viewed (user id). Set by App Clip when it parses the URL.
    @Published var ownerId: String? = nil

    private let baseURL = URL(string: "https://us-central1-cardinalapp-4279c.cloudfunctions.net")!
    private let deviceIdKey = "clipDeviceId"
    private let visitorNameKey = "clipVisitorName"
    private init() {}

    var deviceId: String {
        if let existing = UserDefaults.standard.string(forKey: deviceIdKey), !existing.isEmpty {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: deviceIdKey)
        return newId
    }

    var visitorName: String {
        (UserDefaults.standard.string(forKey: visitorNameKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func logEvent(action: String, meta: [String: String]? = nil) {
        guard let ownerId = ownerId, ownerId.isEmpty == false else { return }
        let url = baseURL.appendingPathComponent("logClipEvent")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "ownerId": ownerId,
            "deviceId": deviceId,
            "visitorName": visitorName.isEmpty ? "anonymous" : visitorName,
            "action": action,
            "meta": meta ?? [:],
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])

        URLSession.shared.dataTask(with: request) { _, _, _ in
            // Fire-and-forget for the clip
        }.resume()
    }

    func fetchAnalytics(ownerId: String) async {
        var comps = URLComponents(url: baseURL.appendingPathComponent("getAnalytics"), resolvingAgainstBaseURL: false)
        comps?.queryItems = [URLQueryItem(name: "ownerId", value: ownerId)]
        guard let url = comps?.url else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return }
            let decoded = try JSONDecoder().decode(GetAnalyticsResponse.self, from: data)
            await MainActor.run {
                self.stats = decoded.stats
                self.events = decoded.events
            }
        } catch {
            // No-op
        }
    }

    // Paginated events fetch for full logs page
    func fetchAnalyticsPage(ownerId: String, pageSize: Int = 50, startAfterId: String? = nil) async throws -> AnalyticsPageResponse {
        var comps = URLComponents(url: baseURL.appendingPathComponent("getAnalyticsPage"), resolvingAgainstBaseURL: false)
        var items: [URLQueryItem] = [
            URLQueryItem(name: "ownerId", value: ownerId),
            URLQueryItem(name: "pageSize", value: String(pageSize))
        ]
        if let startAfterId = startAfterId, startAfterId.isEmpty == false {
            items.append(URLQueryItem(name: "startAfterId", value: startAfterId))
        }
        comps?.queryItems = items
        guard let url = comps?.url else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(AnalyticsPageResponse.self, from: data)
        return decoded
    }
}

struct AnalyticsStats: Codable {
    let uniqueVisitors: Int
    let totalActions: Int
}

struct AnalyticsEvent: Codable, Identifiable {
    let id: String
    let action: String
    let visitorName: String
    let deviceId: String
    let timestamp: String
    let meta: [String: String]?
}

struct GetAnalyticsResponse: Codable {
    let stats: AnalyticsStats
    let events: [AnalyticsEvent]
}

struct AnalyticsPageResponse: Codable {
    let events: [AnalyticsEvent]
    let nextCursor: String?
}


