//
//  ColorExtensions.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-10.
//

import SwiftUI

extension Color {
    static let homeAccent = Color(red: 1.0, green: 0.82, blue: 0.99)
    static let navAccent = Color(red: 1.0, green: 0.76, blue: 0.984)
    static let homeCard = Color(red: 1.0, green: 0.83, blue: 0.99)
    static let signOutButton = Color(red: 1.0, green: 0.77, blue: 0.79)
    static let aboutAccent = Color(red: 0.89, green: 0.82, blue: 1.0)
    static let experiencesAccent = Color(red: 0.72, green: 0.97, blue: 0.87)
    static let experiencesBackground = Color.experiencesAccent.opacity(0.04)
    static let projectsAccent = Color(red: 1.0, green: 0.82, blue: 0.99)
    static let projectsBackground = Color.projectsAccent.opacity(0.1)
    static let textSecondary = Color("TextPrimary").opacity(0.5)
}
