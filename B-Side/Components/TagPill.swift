//
//  TagPill.swift
//  Side-B
//

import SwiftUI

struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(Color.tagForeground)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.tagBackground)
            .clipShape(RoundedRectangle(cornerRadius: BSideLayout.radiusMedium))
    }
}

#Preview {
    VStack(alignment: .leading) {
        TagPill(text: "Udon")
        TagPill(text: "Restaurant")
        TagPill(text: "Japanese Restaurant")
        TagPill(text: "Really Long Restaurant Recommendation")
    }
}
