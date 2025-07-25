//
// ContentView.swift
// Cardinal
//
// Created by Rick Liu on 2025-07-24.
//
import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack {
                HighlightsView()
                SkillsTickerView()
                ProjectsView()
            }
            .frame(
                maxWidth: .infinity,
                alignment: .topLeading
            )
            .foregroundColor(.black)
            .padding(.top, 64)
        }
        .preferredColorScheme(.light)
    }
}