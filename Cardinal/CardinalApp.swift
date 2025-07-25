//
//  CardinalApp.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-07-24.
//

import SwiftUI

@main
struct CardinalApp: App {
    init() {
        UIFont.registerCustomFonts()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
