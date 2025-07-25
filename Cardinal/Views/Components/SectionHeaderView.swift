//
//  SectionHeaderView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-07-25.
//

import SwiftUI

private let h1 = FontSize.h1
private let subtitle = FontSize.subtitle

struct SectionHeaderView: View {
    let titleText: String
    let subtitleText: String

    var body: some View {
            VStack (alignment: .leading, spacing: 8){
                Text(titleText)
                    .font(.system(size: h1, weight: .bold, design: .rounded))
                Text(subtitleText)
                    .font(.mabryPro(size: subtitle))
            }
        }
}