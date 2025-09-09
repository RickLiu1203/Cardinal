//
//  TextView.swift
//  Cardinal
//
//  Created by Rick Liu on 2025-09-08.
//

import SwiftUI

struct TextView: View {
    let blocks: [PortfolioView.PresentableTextBlock]

    var body: some View {
        if !blocks.isEmpty {
            Section(header: Text("Text Blocks")) {
                ForEach(blocks) { block in
                    VStack(alignment: .leading, spacing: 6) {
                        if !block.header.isEmpty {
                            Text(block.header)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        if !block.body.isEmpty {
                            Text(block.body)
                                .font(.footnote)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}

