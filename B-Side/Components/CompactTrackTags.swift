//
//  CompactTrackTags.swift
//  Side-B
//

import SwiftUI

struct CompactTrackTags: View {
    let tags: [String]

    var body: some View {
        if !tags.isEmpty {
            TagFlowLayout(spacing: 6) {
                ForEach(Array(tags.prefix(2)), id: \.self) { tag in
                    TagPill(text: tag)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Tags")
            .accessibilityValue(tags.prefix(2).formatted())
        }
    }
}
