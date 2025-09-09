//
//  FormViewModel.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-07.
//


import Foundation
import FirebaseFirestore
import FirebaseStorage
#if !APPCLIP
import FirebaseAuth
#endif

class FormViewModel: ObservableObject {
    enum SectionType: String, CaseIterable, Identifiable, Equatable {
        case personalDetails
        case experience
        case projects
        case skills
        case resume
        case about
        var id: String { rawValue }
        var title: String {
            switch self {
            case .personalDetails: return "Personal Details"
            case .experience: return "Experience"
            case .projects: return "Projects"
            case .skills: return "Skills"
            case .resume: return "Resume"
            case .about: return "About"
            }
        }
    }
    @Published var selectedSections: [SectionType] = []
    struct ExperienceData: Identifiable, Equatable, Codable {
        let id: String
        let company: String
        let role: String
        let startDateString: String
        let endDateString: String? // nil means "Present"
        let description: String?
    }
    struct AboutData: Equatable {
        let header: String
        let subtitle: String
        let body: String
    }
    struct ResumeData: Identifiable, Equatable, Codable {
        let id: String
        let fileName: String
        let downloadURL: String
        let uploadedAt: Date
    }
    struct SkillsData: Identifiable, Equatable, Codable {
        let id: String
        let skills: [String] // Array of individual skill strings
    }
    struct ProjectData: Identifiable, Equatable, Codable {
        let id: String
        let title: String
        let description: String?
        let tools: [String] // Array of individual tool strings
        let link: String?
    }
    struct PersonalDetailsData: Equatable {
        let firstName: String
        let lastName: String
        let email: String
        let linkedIn: String
        let phoneNumber: String
        let github: String
        let website: String
    }
    @Published var personalDetails: PersonalDetailsData?
    @Published var about: AboutData?
    @Published var experiences: [ExperienceData] = []
    @Published var resume: ResumeData?
    @Published var skills: SkillsData?
    @Published var projects: [ProjectData] = []
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    var currentUserId: String? {
        #if !APPCLIP
        return Auth.auth().currentUser?.uid
        #else
        return nil
        #endif
    }
    var availableSections: [SectionType] {
        SectionType.allCases.filter { type in
            // Allow multiple Experiences and Projects; others are exclusive
            if type == .experience || type == .projects { return true }
            return !selectedSections.contains(type)
        }
    }
    func addSection(_ type: SectionType) {
        guard !selectedSections.contains(type) else { return }
        selectedSections.append(type)
    }
    
    func reorderSections(from sourceIndexSet: IndexSet, to destinationIndex: Int) {
        selectedSections.move(fromOffsets: sourceIndexSet, toOffset: destinationIndex)
        
        // Save the new order to Firebase if user is authenticated
        if let userId = currentUserId {
            Task {
                await saveSectionOrder(userId: userId)
            }
        }
    }
    
    private func saveSectionOrder(userId: String) async {
        do {
            let orderArray = selectedSections.map { $0.rawValue }
            let payload: [String: Any] = [
                "sectionOrder": orderArray,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            try await db.collection("users").document(userId).collection("settings").document("sectionOrder").setData(payload, merge: true)
        } catch {
            print("Error saving section order: \(error)")
        }
    }
    
    func fetchSectionOrder(userId: String) async {
        do {
            let doc = try await db.collection("users").document(userId)
                .collection("settings").document("sectionOrder")
                .getDocument()
            
            if let data = doc.data(),
               let orderArray = data["sectionOrder"] as? [String] {
                let orderedSections = orderArray.compactMap { SectionType(rawValue: $0) }
                await MainActor.run {
                    // Only update if we have a saved order
                    if !orderedSections.isEmpty {
                        // Filter to sections that we actually have data for
                        let sectionsWithData = orderedSections.filter { section in
                            switch section {
                            case .personalDetails:
                                return personalDetails != nil
                            case .about:
                                return about != nil
                            case .experience:
                                return !experiences.isEmpty
                            case .resume:
                                return resume != nil
                            case .skills:
                                return skills != nil
                            case .projects:
                                return !projects.isEmpty
                            }
                        }
                        
                        // Add any sections with data that weren't in the saved order
                        let currentSectionsSet = Set(selectedSections)
                        let newSections = currentSectionsSet.filter { !orderedSections.contains($0) }
                        
                        self.selectedSections = sectionsWithData + Array(newSections)
                        print("✅ Applied section order: \(self.selectedSections.map { $0.rawValue })")
                    }
                }
            }
        } catch {
            print("Error fetching section order: \(error)")
        }
    }
    func savePersonalDetails(_ data: PersonalDetailsData, userId: String) async throws {
        let payload: [String: Any] = [
            "firstName": data.firstName,
            "lastName": data.lastName,
            "email": data.email,
            "linkedIn": data.linkedIn,
            "phoneNumber": data.phoneNumber,
            "github": data.github,
            "website": data.website
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
                let phoneNumber = data["phoneNumber"] as? String ?? ""
                let github = data["github"] as? String ?? ""
                let website = data["website"] as? String ?? ""
                let model = PersonalDetailsData(firstName: firstName, lastName: lastName, email: email, linkedIn: linkedIn, phoneNumber: phoneNumber, github: github, website: website)
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
        about = nil
        experiences.removeAll()
        resume = nil
        skills = nil
        projects.removeAll()
    }

    // MARK: - About
    func saveAbout(_ header: String, subtitle: String, body: String, userId: String) async throws {
        let payload: [String: Any] = [
            "header": header,
            "subtitle": subtitle,
            "body": body,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("users").document(userId).collection("sections").document("about").setData(payload, merge: true)
        await MainActor.run {
            self.about = AboutData(header: header, subtitle: subtitle, body: body)
        }
    }
    func fetchAbout(userId: String) async {
        do {
            let snapshot = try await db.collection("users").document(userId).collection("sections").document("about").getDocument()
            if let data = snapshot.data() {
                let header = data["header"] as? String ?? ""
                let subtitle = data["subtitle"] as? String ?? ""
                let body = data["body"] as? String ?? ""
                let aboutData = AboutData(header: header, subtitle: subtitle, body: body)
                await MainActor.run {
                    self.about = aboutData
                    if !self.selectedSections.contains(.about) {
                        self.selectedSections.append(.about)
                    }
                }
            }
        } catch {
        }
    }

    // MARK: - Experiences
    func addExperienceLocally(company: String, role: String, startDate: Date, endDate: Date?, description: String?) {
        let df = DateFormatter()
        df.dateStyle = .medium
        let startStr = df.string(from: startDate)
        let endStr = endDate.map { df.string(from: $0) }
        let model = ExperienceData(id: UUID().uuidString, company: company, role: role, startDateString: startStr, endDateString: endStr, description: description)
        experiences.append(model)
        if selectedSections.contains(.experience) == false {
            selectedSections.append(.experience)
        }
        experiences.sort { a, b in
            switch (a.endDateString, b.endDateString) {
            case (nil, _?): return true
            case (_?, nil): return false
            case let (l?, r?): return l > r
            default: return a.startDateString > b.startDateString
            }
        }
    }
    func saveExperience(company: String, role: String, startDate: Date, endDate: Date?, description: String?, userId: String) async throws {
        let df = DateFormatter()
        df.dateStyle = .medium
        let payload: [String: Any] = [
            "company": company,
            "role": role,
            "startDateString": df.string(from: startDate),
            "endDateString": endDate != nil ? df.string(from: endDate!) : NSNull(),
            "description": description ?? "",
            "createdAt": FieldValue.serverTimestamp()
        ]
        _ = try await db.collection("users").document(userId)
            .collection("sections").document("experiences")
            .collection("items").addDocument(data: payload)
    }
    func fetchExperiences(userId: String) async {
        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("sections").document("experiences")
                .collection("items")
                .getDocuments()
            var list: [ExperienceData] = []
            for doc in snapshot.documents {
                let data = doc.data()
                let company = data["company"] as? String ?? ""
                let role = data["role"] as? String ?? ""
                let startStr = data["startDateString"] as? String ?? ""
                let endAny = data["endDateString"]
                let endStr = endAny as? String
                let desc = data["description"] as? String
                list.append(ExperienceData(id: doc.documentID, company: company, role: role, startDateString: startStr, endDateString: endStr, description: desc))
            }
            list.sort { a, b in
                switch (a.endDateString, b.endDateString) {
                case (nil, _?): return true
                case (_?, nil): return false
                case let (l?, r?): return l > r
                default: return a.startDateString > b.startDateString
                }
            }
            let finalList = list
            await MainActor.run {
                self.experiences = finalList
                if !finalList.isEmpty && !self.selectedSections.contains(.experience) {
                    self.selectedSections.append(.experience)
                }
            }
        } catch {
        }
    }
    
    // MARK: - Resume
    func saveResume(fileName: String, fileData: Data, userId: String) async throws {
        print("🔄 Starting resume upload for user: \(userId)")
        print("📁 File: \(fileName)")
        print("📊 File size: \(fileData.count) bytes")
        
        // Upload file to Firebase Storage
        let storageRef = storage.reference().child("resumes/\(userId)/\(UUID().uuidString)_\(fileName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        metadata.contentDisposition = "inline"
        
        print("⬆️ Uploading to Firebase Storage...")
        let _ = try await storageRef.putDataAsync(fileData, metadata: metadata)
        let firebaseURL = try await storageRef.downloadURL()
        print("✅ Upload complete. Firebase URL: \(firebaseURL)")
        
        // Save metadata to Firestore with the tokenized Firebase URL
        let payload: [String: Any] = [
            "fileName": fileName,
            "downloadURL": firebaseURL.absoluteString,
            "firebaseURL": firebaseURL.absoluteString,
            "uploadedAt": FieldValue.serverTimestamp()
        ]
        
        print("💾 Saving metadata to Firestore...")
        let _ = try await db.collection("users").document(userId)
            .collection("sections").document("resume")
            .setData(payload, merge: true)
        print("✅ Firestore save complete")
        
        // Update local state
        let resumeData = ResumeData(
            id: "resume",
            fileName: fileName,
            downloadURL: firebaseURL.absoluteString,
            uploadedAt: Date()
        )
        
        await MainActor.run {
            self.resume = resumeData
            if !self.selectedSections.contains(.resume) {
                self.selectedSections.append(.resume)
            }
            print("✅ Local state updated. Resume sections: \(self.selectedSections)")
        }
    }
    
    func fetchResume(userId: String) async {
        do {
            let doc = try await db.collection("users").document(userId)
                .collection("sections").document("resume")
                .getDocument()
            
            if let data = doc.data() {
                let fileName = data["fileName"] as? String ?? ""
                // Prefer firebaseURL if present, fall back to downloadURL
                var downloadURL = (data["firebaseURL"] as? String) ?? (data["downloadURL"] as? String) ?? ""
                let timestamp = data["uploadedAt"] as? Timestamp
                let uploadedAt = timestamp?.dateValue() ?? Date()
                
                // Repair legacy custom-domain URLs by generating a fresh tokenized URL
                if downloadURL.contains("cardinalapp.me/files/") {
                    if let range = downloadURL.range(of: "/files/") {
                        let rawPath = String(downloadURL[range.upperBound...])
                        let storagePath = rawPath.removingPercentEncoding ?? rawPath
                        // Attempt to fetch a new tokenized URL from Firebase Storage
                        do {
                            let newURL = try await storage.reference(withPath: storagePath).downloadURL()
                            downloadURL = newURL.absoluteString
                            // Persist the fixed URL back to Firestore for future loads
                            try await db.collection("users").document(userId)
                                .collection("sections").document("resume")
                                .setData([
                                    "downloadURL": downloadURL,
                                    "firebaseURL": downloadURL,
                                    "updatedAt": FieldValue.serverTimestamp()
                                ], merge: true)
                        } catch {
                            // If we can't repair, keep the existing URL
                        }
                    }
                }
                
                let resumeData = ResumeData(
                    id: "resume",
                    fileName: fileName,
                    downloadURL: downloadURL,
                    uploadedAt: uploadedAt
                )
                
                await MainActor.run {
                    self.resume = resumeData
                    if !self.selectedSections.contains(.resume) {
                        self.selectedSections.append(.resume)
                    }
                }
            }
        } catch {
        }
    }
    
    // MARK: - Skills
    func saveSkills(skillsString: String, userId: String) async throws {
        print("🔄 Starting skills save for user: \(userId)")
        print("🏷️ Skills input: \(skillsString)")
        
        // Parse comma-separated skills and clean them up
        let skillsArray = skillsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        print("📋 Parsed skills: \(skillsArray)")
        
        // Save to Firestore
        let payload: [String: Any] = [
            "skills": skillsArray,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        print("💾 Saving skills to Firestore...")
        let _ = try await db.collection("users").document(userId)
            .collection("sections").document("skills")
            .setData(payload, merge: true)
        print("✅ Firestore save complete")
        
        // Update local state
        let skillsData = SkillsData(id: "skills", skills: skillsArray)
        
        await MainActor.run {
            self.skills = skillsData
            if !self.selectedSections.contains(.skills) {
                self.selectedSections.append(.skills)
            }
            print("✅ Local state updated. Skills: \(skillsArray)")
        }
    }
    
    func fetchSkills(userId: String) async {
        do {
            let doc = try await db.collection("users").document(userId)
                .collection("sections").document("skills")
                .getDocument()
            
            if let data = doc.data() {
                let skillsArray = data["skills"] as? [String] ?? []
                
                let skillsData = SkillsData(id: "skills", skills: skillsArray)
                
                await MainActor.run {
                    self.skills = skillsData
                    if !skillsArray.isEmpty && !self.selectedSections.contains(.skills) {
                        self.selectedSections.append(.skills)
                    }
                }
            }
        } catch {
        }
    }
    
    // MARK: - Projects
    func addProjectLocally(title: String, description: String?, toolsString: String, link: String?) {
        // Parse comma-separated tools and clean them up
        let toolsArray = toolsString.isEmpty ? [] : toolsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let project = ProjectData(
            id: UUID().uuidString,
            title: title,
            description: description?.isEmpty == false ? description : nil,
            tools: toolsArray,
            link: link?.isEmpty == false ? link : nil
        )
        
        projects.append(project)
        if selectedSections.contains(.projects) == false {
            selectedSections.append(.projects)
        }
    }
    
    func saveProject(title: String, description: String?, toolsString: String, link: String?, userId: String) async throws {
        print("🔄 Starting project save for user: \(userId)")
        print("📝 Project: \(title)")
        
        // Parse comma-separated tools
        let toolsArray = toolsString.isEmpty ? [] : toolsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        print("🔧 Tools: \(toolsArray)")
        
        // Save to Firestore
        let payload: [String: Any] = [
            "title": title,
            "description": description?.isEmpty == false ? description! : "",
            "tools": toolsArray,
            "link": link?.isEmpty == false ? link! : "",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        print("💾 Saving project to Firestore...")
        let _ = try await db.collection("users").document(userId)
            .collection("sections").document("projects")
            .collection("items").addDocument(data: payload)
        print("✅ Firestore save complete")
    }
    
    func fetchProjects(userId: String) async {
        do {
            let snapshot = try await db.collection("users").document(userId)
                .collection("sections").document("projects")
                .collection("items")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            var list: [ProjectData] = []
            for doc in snapshot.documents {
                let data = doc.data()
                let title = data["title"] as? String ?? ""
                let description = data["description"] as? String
                let tools = data["tools"] as? [String] ?? []
                let link = data["link"] as? String
                
                list.append(ProjectData(
                    id: doc.documentID,
                    title: title,
                    description: description?.isEmpty == false ? description : nil,
                    tools: tools,
                    link: link?.isEmpty == false ? link : nil
                ))
            }
            
            let finalList = list
            await MainActor.run {
                self.projects = finalList
                if !finalList.isEmpty && !self.selectedSections.contains(.projects) {
                    self.selectedSections.append(.projects)
                }
            }
        } catch {
        }
    }

    // MARK: - Delete: Sections
    func deletePersonalDetails() async {
        guard let userId = currentUserId else { return }
        do {
            try await db.collection("users").document(userId)
                .collection("sections").document("personalDetails")
                .delete()
        } catch { }
        await MainActor.run {
            self.personalDetails = nil
            self.selectedSections.removeAll { $0 == .personalDetails }
        }
    }
    func deleteResume() async {
        guard let userId = currentUserId else { return }
        do {
            try await db.collection("users").document(userId)
                .collection("sections").document("resume")
                .delete()
        } catch { }
        await MainActor.run {
            self.resume = nil
            self.selectedSections.removeAll { $0 == .resume }
        }
    }
    func deleteSkills() async {
        guard let userId = currentUserId else { return }
        do {
            try await db.collection("users").document(userId)
                .collection("sections").document("skills")
                .delete()
        } catch { }
        await MainActor.run {
            self.skills = nil
            self.selectedSections.removeAll { $0 == .skills }
        }
    }

    // MARK: - Delete: Items
    func deleteExperience(id: String) async {
        guard let userId = currentUserId else { return }
        do {
            try await db.collection("users").document(userId)
                .collection("sections").document("experiences")
                .collection("items").document(id).delete()
        } catch { }
        await MainActor.run {
            self.experiences.removeAll { $0.id == id }
            if self.experiences.isEmpty {
                self.selectedSections.removeAll { $0 == .experience }
            }
        }
    }
    func deleteAbout() async {
        guard let userId = currentUserId else { return }
        do {
            try await db.collection("users").document(userId)
                .collection("sections").document("about")
                .delete()
        } catch { }
        await MainActor.run {
            self.about = nil
            self.selectedSections.removeAll { $0 == .about }
        }
    }
    func deleteProject(id: String) async {
        guard let userId = currentUserId else { return }
        do {
            try await db.collection("users").document(userId)
                .collection("sections").document("projects")
                .collection("items").document(id).delete()
        } catch { }
        await MainActor.run {
            self.projects.removeAll { $0.id == id }
            if self.projects.isEmpty {
                self.selectedSections.removeAll { $0 == .projects }
            }
        }
    }

    // MARK: - Update: Items
    func updateAbout(header: String, subtitle: String, body: String) async {
        guard let userId = currentUserId else { return }
        let payload: [String: Any] = [
            "header": header,
            "subtitle": subtitle,
            "body": body
        ]
        do {
            try await db.collection("users").document(userId)
                .collection("sections").document("about")
                .setData(payload, merge: true)
            await MainActor.run {
                self.about = AboutData(header: header, subtitle: subtitle, body: body)
            }
        } catch { }
    }
    func updateExperience(id: String, company: String, role: String, startDate: Date, endDate: Date?, description: String?) async {
        guard let userId = currentUserId else { return }
        let df = DateFormatter()
        df.dateStyle = .medium
        let payload: [String: Any] = [
            "company": company,
            "role": role,
            "startDateString": df.string(from: startDate),
            "endDateString": endDate != nil ? df.string(from: endDate!) : NSNull(),
            "description": description ?? ""
        ]
        do {
            try await db.collection("users").document(userId)
                .collection("sections").document("experiences")
                .collection("items").document(id).setData(payload, merge: true)
            await MainActor.run {
                if let idx = self.experiences.firstIndex(where: { $0.id == id }) {
                    let startStr = df.string(from: startDate)
                    let endStr = endDate.map { df.string(from: $0) }
                    self.experiences[idx] = ExperienceData(id: id, company: company, role: role, startDateString: startStr, endDateString: endStr, description: description)
                    self.experiences.sort { a, b in
                        switch (a.endDateString, b.endDateString) {
                        case (nil, _?): return true
                        case (_?, nil): return false
                        case let (l?, r?): return l > r
                        default: return a.startDateString > b.startDateString
                        }
                    }
                }
            }
        } catch { }
    }
    func updateProject(id: String, title: String, description: String?, toolsString: String, link: String?) async {
        guard let userId = currentUserId else { return }
        let toolsArray = toolsString.isEmpty ? [] : toolsString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let payload: [String: Any] = [
            "title": title,
            "description": description?.isEmpty == false ? description! : "",
            "tools": toolsArray,
            "link": link?.isEmpty == false ? link! : ""
        ]
        do {
            try await db.collection("users").document(userId)
                .collection("sections").document("projects")
                .collection("items").document(id).setData(payload, merge: true)
            await MainActor.run {
                if let idx = self.projects.firstIndex(where: { $0.id == id }) {
                    self.projects[idx] = ProjectData(
                        id: id,
                        title: title,
                        description: description?.isEmpty == false ? description : nil,
                        tools: toolsArray,
                        link: link?.isEmpty == false ? link : nil
                    )
                }
            }
        } catch { }
    }
}
