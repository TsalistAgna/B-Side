//
//  TrackTagLayout.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 16/09/26.
//

import SwiftUI

struct TrackTagLayout: View {

    let tags: [String]

    private var uniqueTags: [String] {

        var result: [String] = []

        for tag in tags {

            if !result.contains(tag) {
                result.append(tag)
            }
        }

        return result
    }

    var body: some View {

        TagFlowLayout(spacing: 6) {

            ForEach(
                uniqueTags,
                id: \.self
            ) { tag in

                TagPill(
                    text: tag
                )
            }
        }
    }
}
