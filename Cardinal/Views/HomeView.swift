//
//  HomeView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//

import SwiftUI
import FirebaseAuth
import CoreNFC
import Foundation

// MARK: - NFC Manager
class NFCManager: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var nfcMessage: String?
    @Published var isWritingToNFC = false
    @Published var writeSuccessful = false
    
    private var nfcSession: NFCNDEFReaderSession?
    private var portfolioURL: String?
    
    func writeToNFC(for user: User) {
        guard NFCNDEFReaderSession.readingAvailable else {
            nfcMessage = "NFC is not available on this device"
            return
        }
        
        portfolioURL = "https://cardinalapp.me/portfolio?id=\(user.uid)"
        isWritingToNFC = true
        writeSuccessful = false
        nfcMessage = nil
        
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        nfcSession?.alertMessage = "Hold your iPhone near an NFC tag to write your portfolio link"
        nfcSession?.begin()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isWritingToNFC = false
            if let nfcError = error as? NFCReaderError {
                switch nfcError.code {
                case .readerSessionInvalidationErrorFirstNDEFTagRead:
                    // Success case - handled in write completion
                    break
                case .readerSessionInvalidationErrorUserCanceled:
                    self.nfcMessage = nil
                default:
                    if !self.writeSuccessful {
                        self.nfcMessage = "NFC write unsuccessful, please try again"
                    }
                }
            }
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Not used for writing
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard tags.count == 1 else {
            session.alertMessage = "Please use only one NFC tag"
            session.restartPolling()
            return
        }
        
        let tag = tags.first!
        session.connect(to: tag) { error in
            if error != nil {
                session.alertMessage = "Connection failed"
                session.invalidate()
                return
            }
            
            tag.queryNDEFStatus { status, _, error in
                if error != nil || status != .readWrite {
                    session.alertMessage = "Tag cannot be written to"
                    session.invalidate()
                    return
                }
                
                guard let portfolioURL = self.portfolioURL,
                      let url = URL(string: portfolioURL),
                      let payload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url) else {
                    session.alertMessage = "Invalid URL"
                    session.invalidate()
                    return
                }
                
                let message = NFCNDEFMessage(records: [payload])
                
                tag.writeNDEF(message) { error in
                    if error != nil {
                        DispatchQueue.main.async {
                            self.writeSuccessful = false
                            self.nfcMessage = "NFC write unsuccessful, please try again"
                        }
                        session.alertMessage = "Write failed"
                    } else {
                        DispatchQueue.main.async {
                            self.writeSuccessful = true
                            self.nfcMessage = "Portfolio link written successfully!"
                        }
                        session.alertMessage = "Success!"
                    }
                    session.invalidate()
                }
            }
        }
    }
}

struct HomeView: View {
    let user: User
    let switchToTab: (Int) -> Void
    @State private var errorMessage: String?
    @State private var isNfcButtonPressed = false
    @StateObject private var nfcManager = NFCManager()
    @StateObject private var analytics = AnalyticsManager.shared
    @EnvironmentObject private var formViewModel: FormViewModel
    
    // Loading states
    @State private var isLoadingAnalytics = true
    @State private var isLoadingPersonalDetails = true
    @State private var isLoadingExperiences = true
    @State private var isLoadingSkills = true
    @State private var isLoadingProjects = true
    
    private var isDataLoading: Bool {
        isLoadingAnalytics || isLoadingPersonalDetails || 
        isLoadingExperiences || isLoadingSkills || isLoadingProjects
    }

    private let logsContainerHeight: CGFloat = 275
    private let maxLogsToRender: Int = 10

    // Cached date formatters to avoid per-row instantiation cost
    private static let isoWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private static let isoBasic: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    private static let displayDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale.current
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "MMM d, yyyy - HH:mm"
        return df
    }()

    private var fullName: String {
        let first = formViewModel.personalDetails?.firstName ?? ""
        let last = formViewModel.personalDetails?.lastName ?? ""
        let name = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        if name.isEmpty { return user.displayName ?? "" }
        return name
    }
    private var emailText: String {
        formViewModel.personalDetails?.email ?? user.email ?? ""
    }
    private var phoneText: String {
        let phone = formViewModel.personalDetails?.phoneNumber ?? ""
        return phone.isEmpty ? "—" : phone
    }
    private var projectsCount: Int { formViewModel.projects.count }
    private var skillsCount: Int { formViewModel.skills?.skills.count ?? 0 }
    private var experiencesCount: Int { formViewModel.experiences.count }

    var body: some View {
        Group {
            if isDataLoading {
                VStack {
                    Spacer()
                    
                    Image("CardinalLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .scaleEffect(isDataLoading ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isDataLoading)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("BackgroundPrimary"))
            } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                    Text("YOUR PORTFOLIO")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(Color("TextPrimary"))
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(fullName.isEmpty ? "" : fullName)
                            .font(.custom("MabryPro-Black", size: 24)) 
                            .foregroundColor(Color("TextPrimary"))
                            .kerning(1)
                        if !(formViewModel.personalDetails?.subtitle ?? "").isEmpty {
                            Text(formViewModel.personalDetails?.subtitle ?? "")
                                .font(.custom("MabryPro-Italic", size: 18))
                                .foregroundColor(Color("TextPrimary"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }


                    // Metrics inside card
                    HStack(spacing: 0) {
                        metricView(icon: "lightbulb", value: skillsCount, label: "SKILLS")
                        Spacer()
                        metricView(icon: "briefcase", value: experiencesCount, label: "EXPERIENCES")
                        Spacer()
                        metricView(icon: "folder", value: projectsCount, label: "PROJECTS")
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.homeCard)
                        .shadow(color: .black, radius: 0, x: 4, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.clear, location: 0.45),
                                    .init(color: Color.white.opacity(0.6), location: 0.65),
                                    .init(color: Color.clear, location: 0.85)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black, lineWidth: 1.5)
                )
                }

                // Interaction Logs preview (non-scrollable, fills container, navigates to full page on tap)
                VStack(alignment: .leading, spacing: 12) {
                    if analytics.events.isEmpty {
                        Text("No interactions yet.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(Array(analytics.events.prefix(3))) { event in
                                ReusableLogRowView(
                                    actionType: event.action,
                                    formattedTime: formattedTimestamp(event.timestamp),
                                    userName: event.visitorName,
                                    link: event.meta?["url"],
                                    shouldTruncate: true
                                )
                                Rectangle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(height: 1)
                            }
                            Button {
                                switchToTab(1)
                            } label: {
                                Text("View All")
                                    .font(.custom("MabryPro-Bold", size: 16))
                                    .foregroundColor(Color("TextPrimary"))
                                    .underline()
                            }
                        }
                        .padding(24)
                        .frame(height: logsContainerHeight)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color("BackgroundPrimary"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black, lineWidth: 1.5)
                )

                // NFC Button styled like design
                HStack(spacing: 8) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.body.weight(.black))
                    Text(nfcManager.isWritingToNFC ? "WRITING TO NFC..." : "WRITE PORTFOLIO TO NFC")
                        .font(.custom("MabryPro-Black", size: 18))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .foregroundColor(Color("TextPrimary"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.black, lineWidth: 1.5)
                )
                .background{
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.homeAccent)
                        .shadow(color: isNfcButtonPressed ? .clear : .black, radius: 0, x: isNfcButtonPressed ? 0 : 4, y: isNfcButtonPressed ? 0 : 4)
                }
                .offset(x: isNfcButtonPressed ? 4 : 0, y: isNfcButtonPressed ? 4 : 0)
                .animation(.easeInOut(duration: 0.1), value: isNfcButtonPressed)
                .onTapGesture {
                    guard !nfcManager.isWritingToNFC && NFCNDEFReaderSession.readingAvailable else { return }
                    
                    withAnimation(.easeInOut(duration: 0.05)) {
                        isNfcButtonPressed = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.05)) {
                            isNfcButtonPressed = false
                        }
                        
                        nfcManager.writeToNFC(for: user)
                    }
                }

                }
                .padding(16)
                .padding(.top, 16)
            }
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 0)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 0)
            }
            .background(Color("BackgroundPrimary"))
            .refreshable {
                await refreshAnalytics()
            }
            }
        }
        .task {
            // Fetch analytics
            await analytics.fetchAnalytics(ownerId: user.uid)
            isLoadingAnalytics = false
            
            // Fetch portfolio data to populate counts and card details
            await formViewModel.fetchPersonalDetails(userId: user.uid)
            isLoadingPersonalDetails = false
            
            await formViewModel.fetchExperiences(userId: user.uid)
            isLoadingExperiences = false
            
            await formViewModel.fetchSkills(userId: user.uid)
            isLoadingSkills = false
            
            await formViewModel.fetchProjects(userId: user.uid)
            isLoadingProjects = false
        }
    }

    // MARK: - Refresh
    private func refreshAnalytics() async {
        // Don't show loading screen on refresh, just refresh the analytics
        await analytics.fetchAnalytics(ownerId: user.uid)
    }

    // MARK: - Subviews
    private func summaryTile(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cornerRadius(12)
    }

    private func metricView(icon: String, value: Int, label: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.black)
                Text("\(value)")
                    .font(.custom("MabryPro-BlackItalic", size: 18))
                    .foregroundColor(Color.black)
            }
            Text(label)
                .font(.custom("MabryPro-Medium", size: 14))
                .foregroundColor(Color("TextPrimary"))
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    // MARK: - Helpers

    private func formattedTimestamp(_ isoString: String) -> String {
        var parsedDate = HomeView.isoWithFractionalSeconds.date(from: isoString)
            ?? HomeView.isoBasic.date(from: isoString)
        if parsedDate == nil, let numeric = Double(isoString) {
            // Fallback: numeric timestamp (sec or ms)
            parsedDate = isoString.count > 11
                ? Date(timeIntervalSince1970: numeric / 1000.0)
                : Date(timeIntervalSince1970: numeric)
        }
        return HomeView.displayDateFormatter.string(from: parsedDate ?? Date())
    }
}

// MARK: - Sign Out
private extension HomeView {
    func signOut() {
        do {
            // Reset section order flag before signing out
            formViewModel.resetSectionOrderFlag()
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
