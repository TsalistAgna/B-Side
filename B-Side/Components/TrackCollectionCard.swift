//
//  TrackCollectionCard.swift
//  Side-B
//

import SwiftUI

struct TrackCollectionCard: View {
    let track: Track

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.surfaceSecondary)

                if let image = track.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(BSideLayout.spacingXS)
                        .accessibilityHidden(true)
                } else {
                    ProgressView()
                        .tint(Color.accentPrimary)
                }
            }
            .frame(height: 120)

            Text(track.title ?? "Untitled Track")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            CompactTrackTags(tags: track.tags)
        }
        .padding(BSideLayout.spacingMD)
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
        .background(Color.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.borderDefault, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(track.title ?? "Untitled Track")
        .accessibilityValue(track.tags.isEmpty ? "" : "Tags: \(track.tags.formatted())")
    }
}
