//
//  HomeView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//

import SwiftUI
import FirebaseAuth
import CoreNFC

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
    @State private var errorMessage: String?
    @StateObject private var nfcManager = NFCManager()
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Welcome to Cardinal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Signed in as")
                    .foregroundColor(.secondary)
                Text(user.email ?? user.displayName ?? user.uid)
                    .font(.headline)
            }
            
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("5")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Cards Created")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("127")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Total Views")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                }
                
                if let nfcMessage = nfcManager.nfcMessage {
                    HStack {
                        if nfcManager.writeSuccessful {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        Text(nfcMessage)
                            .foregroundColor(nfcManager.writeSuccessful ? .green : .red)
                            .multilineTextAlignment(.center)
                            .font(.footnote)
                    }
                }
                
                Button {
                    nfcManager.writeToNFC(for: user)
                } label: {
                    HStack {
                        Image(systemName: "dot.radiowaves.left.and.right")
                        Text(nfcManager.isWritingToNFC ? "Writing to NFC..." : "Write Portfolio to NFC")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.bordered)
                .disabled(nfcManager.isWritingToNFC || !NFCNDEFReaderSession.readingAvailable)
                
                Button(role: .destructive) {
                    signOut()
                } label: {
                    Text("Sign out")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

// MARK: - Sign Out
private extension HomeView {
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
