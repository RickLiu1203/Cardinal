//
//  PortfolioView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI

struct PortfolioView: View {
    struct PresentablePersonalDetails: Equatable {
        let firstName: String
        let lastName: String
        let email: String
        let linkedIn: String
    }
    
    // Optional override for App Clip or callers that want to inject data directly
    private let overridePersonalDetails: PresentablePersonalDetails?
    
    #if !APPCLIP
    @EnvironmentObject var formViewModel: FormViewModel
    #endif
    
    init(overridePersonalDetails: PresentablePersonalDetails? = nil) {
        self.overridePersonalDetails = overridePersonalDetails
    }
    
    private var effectivePersonalDetails: PresentablePersonalDetails? {
        if let injected = overridePersonalDetails { return injected }
        #if !APPCLIP
        if let pd = formViewModel.personalDetails {
            return .init(firstName: pd.firstName, lastName: pd.lastName, email: pd.email, linkedIn: pd.linkedIn)
        }
        #endif
        return nil
    }
    
    var body: some View {
        NavigationStack {
            List {
                if let pd = effectivePersonalDetails {
                    Section(header: Text("Personal Details")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(pd.firstName) \(pd.lastName)")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(pd.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if pd.linkedIn.isEmpty == false {
                                Text(pd.linkedIn)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                if effectivePersonalDetails == nil {
                    Section {
                        #if APPCLIP
                        Text("No details yet.")
                            .foregroundColor(.secondary)
                        Text("Open from your link to see details.")
                            .foregroundColor(.secondary)
                        #else
                        Text("No details yet. Add your info in the Details tab.")
                            .foregroundColor(.secondary)
                        #endif
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Portfolio")
        }
    }
}

