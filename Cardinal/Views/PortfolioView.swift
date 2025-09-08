//
//  PortfolioView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI
import FirebaseAuth

struct PortfolioView: View {
    @EnvironmentObject var formViewModel: FormViewModel
    
    var body: some View {
        NavigationStack {
            List {
                if let pd = formViewModel.personalDetails {
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
                
                if formViewModel.personalDetails == nil {
                    Section {
                        Text("No details yet. Add your info in the Details tab.")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Portfolio")
            .onAppear {
                if let uid = Auth.auth().currentUser?.uid {
                    Task { await formViewModel.fetchPersonalDetails(userId: uid) }
                }
            }
        }
    }
}

