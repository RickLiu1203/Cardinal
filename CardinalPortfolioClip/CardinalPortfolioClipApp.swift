//
//  CardinalPortfolioClipApp.swift
//  CardinalPortfolioClip
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI

@main
struct CardinalPortfolioClipApp: App {
    @StateObject private var vm = PortfolioViewModel()
    init() {}

    var body: some Scene {
        WindowGroup {
            Group {
                if let pd = vm.personalDetails {
                    PortfolioView(
                        overridePersonalDetails: .init(
                            firstName: pd.firstName,
                            lastName: pd.lastName,
                            email: pd.email,
                            linkedIn: pd.linkedIn
                        )
                    )
                } else {
                    PortfolioView(overridePersonalDetails: nil)
                }
            }
            .onOpenURL { url in
                vm.apply(url: url)
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                if let url = (activity.webpageURL ?? activity.referrerURL) {
                    vm.apply(url: url)
                }
            }
        }
    }
}
