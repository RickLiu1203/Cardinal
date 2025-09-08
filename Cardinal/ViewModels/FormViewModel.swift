//
//  FormViewModel.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//


import Foundation
import FirebaseFirestore

class FormViewModel: ObservableObject {
    enum SectionType: String, CaseIterable, Identifiable, Equatable {
        case personalDetails
        case experience
        case projects
        case skills
        case resume
        case list
        var id: String { rawValue }
        var title: String {
            switch self {
            case .personalDetails: return "Personal Details"
            case .experience: return "Experience"
            case .projects: return "Projects"
            case .skills: return "Skills"
            case .resume: return "Resume"
            case .list: return "List"
            }
        }
    }
    @Published var selectedSections: [SectionType] = []
    struct PersonalDetailsData: Equatable {
        let firstName: String
        let lastName: String
        let email: String
        let linkedIn: String
    }
    @Published var personalDetails: PersonalDetailsData?
    private let db = Firestore.firestore()
    var availableSections: [SectionType] {
        SectionType.allCases.filter { type in
            !selectedSections.contains(type)    
        }
    }
    func addSection(_ type: SectionType) {
        guard !selectedSections.contains(type) else { return }
        selectedSections.append(type)
    }
    func savePersonalDetails(_ data: PersonalDetailsData, userId: String) async throws {
        let payload: [String: Any] = [
            "firstName": data.firstName,
            "lastName": data.lastName,
            "email": data.email,
            "linkedIn": data.linkedIn
        ]
        try await db.collection("users").document(userId).collection("sections").document("personalDetails").setData(payload, merge: true)
        await MainActor.run {
            self.personalDetails = data
        }
    }
    func fetchPersonalDetails(userId: String) async {
        do {
            let snapshot = try await db.collection("users").document(userId).collection("sections").document("personalDetails").getDocument()
            if let data = snapshot.data() {
                let firstName = data["firstName"] as? String ?? ""
                let lastName = data["lastName"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                let linkedIn = data["linkedIn"] as? String ?? ""
                let model = PersonalDetailsData(firstName: firstName, lastName: lastName, email: email, linkedIn: linkedIn)
                await MainActor.run {
                    self.personalDetails = model
                    if !self.selectedSections.contains(.personalDetails) {
                        self.selectedSections.append(.personalDetails)
                    }
                }
            }
        } catch {
        }
    }
    /// Clears all user-specific in-memory form data. Call this on logout or account switch.
    func clearUserData() {
        personalDetails = nil
        selectedSections.removeAll()
    }
}