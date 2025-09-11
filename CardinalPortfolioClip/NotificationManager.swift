import Foundation
import UserNotifications
import SwiftUI
import UIKit

@MainActor
final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let notifiedUsersKey = "appClipNotifiedUsers"
    private var apnsDeviceTokenHex: String?
    private var pendingOwnerId: String?
    private var pendingPersonalDetails: PersonalDetails?
    
    private override init() {
        super.init()
    }
    
    func scheduleWelcomeNotification(for ownerId: String, personalDetails: PersonalDetails?) async {
        let currentSettings = await UNUserNotificationCenter.current().notificationSettings()
        
        if currentSettings.authorizationStatus == .notDetermined {
            do {
                _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .provisional])
            } catch {
            }
        }
        
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
        
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        
        if apnsDeviceTokenHex == nil {
            pendingOwnerId = ownerId
            pendingPersonalDetails = personalDetails
            return
        }
        
        if let token = apnsDeviceTokenHex, !token.isEmpty {
            await scheduleServerPush(ownerId: ownerId, deviceToken: token, personalDetails: personalDetails)
            return
        }
    }

    func setAPNsDeviceToken(_ tokenData: Data) {
        let hex = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        
        if apnsDeviceTokenHex == hex {
            return
        }
        
        apnsDeviceTokenHex = hex
        
        if let ownerId = pendingOwnerId {
            let details = pendingPersonalDetails
            pendingOwnerId = nil
            pendingPersonalDetails = nil
            Task { [weak self] in
                guard let self else { return }
                await self.scheduleServerPush(ownerId: ownerId, deviceToken: hex, personalDetails: details)
            }
        }
    }

    private func scheduleServerPush(ownerId: String, deviceToken: String, personalDetails: PersonalDetails?) async {
        let environment: String = {
            #if targetEnvironment(simulator)
            return "sandbox"
            #endif
            
            if Bundle.main.bundlePath.contains("CoreSimulator") {
                return "sandbox"
            }
            
            #if DEBUG
            return "sandbox"
            #else
            if Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil {
                return "sandbox"
            }
            return "production"
            #endif
        }()
        
        let primaryFunction = environment == "sandbox" ? "scheduleClipPushDev" : "scheduleClipPush"
        let fallbackFunction = environment == "sandbox" ? "scheduleClipPush" : "scheduleClipPushDev"
        
        let body: [String: Any] = [
            "token": deviceToken,
            "seconds": 180,
            "bundleId": "com.rzliu.Cardinal.Clip",
            "title": "\(personalDetails != nil ? "\(personalDetails!.firstName.capitalized)'s" : "My") Portfolio!",
            "body": "Please feel free to reach out via email or LinkedIn!",
            "ownerId": ownerId,
            "deviceId": AnalyticsManager.shared.deviceId,
            "visitorName": AnalyticsManager.shared.visitorName.isEmpty ? "anonymous" : AnalyticsManager.shared.visitorName
        ]
        
        let primarySuccess = await tryNotificationFunction(
            functionName: primaryFunction,
            body: body,
            isPrimary: true
        )
        
        if !primarySuccess {
            _ = await tryNotificationFunction(
                functionName: fallbackFunction,
                body: body,
                isPrimary: false
            )
        }
    }
    
    private func tryNotificationFunction(
        functionName: String,
        body: [String: Any],
        isPrimary: Bool
    ) async -> Bool {
        let url = FirebaseConfig.shared.functionsBaseURL.appendingPathComponent(functionName)
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 200 {
                    return true
                } else {
                    if let errorString = String(data: data, encoding: .utf8) {
                        if isPrimary && (
                            errorString.contains("BadEnvironmentKeyInToken") ||
                            errorString.contains("BadDeviceToken") ||
                            errorString.contains("DeviceTokenNotForTopic")
                        ) {
                            return false
                        }
                    }
                    return true
                }
            }
            return true
        } catch {
            return !isPrimary
        }
    }
    
    private func getNotifiedUsers() -> Set<String> {
        let stored = UserDefaults.standard.object(forKey: notifiedUsersKey) as? [String] ?? []
        return Set(stored)
    }
    
    private func addNotifiedUser(_ userKey: String) {
        var notifiedUsers = getNotifiedUsers()
        notifiedUsers.insert(userKey)
        
        let sortedUsers = Array(notifiedUsers).sorted()
        let limitedUsers = sortedUsers.suffix(100)
        
        UserDefaults.standard.set(Array(limitedUsers), forKey: notifiedUsersKey)
    }
    
    func clearNotificationHistory() {
        UserDefaults.standard.removeObject(forKey: notifiedUsersKey)
    }
    
    func resetAppClipCompletely() {
        clearNotificationHistory()
        
        pendingOwnerId = nil
        pendingPersonalDetails = nil
        apnsDeviceTokenHex = nil
        
        let defaults = UserDefaults.standard
        let allKeys = Array(defaults.dictionaryRepresentation().keys)
        for key in allKeys {
            if key.starts(with: "notificationAttempt_") {
                defaults.removeObject(forKey: key)
            }
        }
        
        AnalyticsManager.shared.clearAllStoredData()
    }
    
    func resetAppClipNotifications() {
        clearNotificationHistory()
        pendingOwnerId = nil
        pendingPersonalDetails = nil
        apnsDeviceTokenHex = nil
    }
    
    private func authorizationStatusName(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .denied: return "denied"
        case .authorized: return "authorized"
        case .provisional: return "provisional"
        case .ephemeral: return "ephemeral"
        @unknown default: return "unknown(\(status.rawValue))"
        }
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
    }
}

