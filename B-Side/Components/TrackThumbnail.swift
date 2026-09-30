//
//  TrackThumbnail.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI

struct TrackThumbnail: View {

    let track: Track

    var body: some View {

        ZStack {

            RoundedRectangle(
                cornerRadius: 10
            )
            .fill(Color.bSideBackground)


            RoundedRectangle(
                cornerRadius: 10
            )
            .stroke(
                Color.blue4,
                lineWidth: 1
            )


            if let image = track.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(Color.blue4)
            }
        }
        .frame(height: 98)
    }
}
