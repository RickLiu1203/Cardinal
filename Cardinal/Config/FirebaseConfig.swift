//
//  FirebaseConfig.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-11.
//

import Foundation

struct FirebaseConfig {
    static let shared = FirebaseConfig()
    
    private init() {}
    
    // Firebase Cloud Functions base URL
    var functionsBaseURL: URL {
        // In production, this would come from a plist or environment variable
        // For development, we'll read from GoogleService-Info.plist to get the project ID
        guard let projectId = getProjectId() else {
            // Fallback to hardcoded value if plist is not available
            return URL(string: "https://us-central1-cardinalapp-4279c.cloudfunctions.net")!
        }
        return URL(string: "https://us-central1-\(projectId).cloudfunctions.net")!
    }
    
    private func getProjectId() -> String? {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let projectId = plist["PROJECT_ID"] as? String else {
            return nil
        }
        return projectId
    }
}
