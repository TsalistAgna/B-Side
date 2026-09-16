//
//  TrackCollectionCard.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 16/09/26.
//

import SwiftUI

struct TrackCollectionCard: View {

    let track: Track

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            // Screenshot
            ZStack {

                RoundedRectangle(
                    cornerRadius: 12
                )
                .fill(Color.blue1)

                Image(
                    uiImage: track.image
                )
                .resizable()
                .scaledToFit()
                .padding(4)
            }
            .frame(height: 120)


            // Title
            Text(
                track.title ?? "Untitled Track"
            )
            .font(
                .system(
                    size: 14,
                    weight: .medium
                )
            )
            .foregroundStyle(Color.blue10)
            .lineLimit(2)
            .frame(
                height: 34,
                alignment: .topLeading
            )


            Spacer()


            CompactTrackTags(
                tags: track.tags
            )
            
        }
        .padding(14)
        .frame(height: 250)
        .background(
            Color.bSideBackground
        )
        .overlay {

            RoundedRectangle(
                cornerRadius: 14
            )
            .stroke(
                Color.blue4,
                lineWidth: 1
            )
        }
    }
}
