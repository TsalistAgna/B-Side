//
//  CompactTrackTags.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 17/09/26.
//

import SwiftUI

struct CompactTrackTags: View {

    let tags: [String]

    var body: some View {

        HStack(spacing: 6) {

            ForEach(
                Array(tags.prefix(2)),
                id: \.self
            ) { tag in

                TagPill(text: tag)
                    .frame(
                        maxWidth: 90,
                        alignment: .leading
                    )
            }

            Spacer(minLength: 0)
        }
        .frame(height: 28)
        .clipped()
    }
}
