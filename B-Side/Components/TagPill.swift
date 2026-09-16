//
//  TagPill.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 16/09/26.
//

import SwiftUI

struct TagPill: View {

    let text: String

    var body: some View {

        Text(text)
            .font(
                .system(
                    size: 11,
                    weight: .medium
                )
            )
            .foregroundStyle(Color.red10)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Color.red2
            )
            .clipShape(
                Capsule()
            )
    }
}


#Preview {

    VStack(alignment: .leading) {

        TagPill(text: "Udon")

        TagPill(text: "Restaurant")

        TagPill(
            text: "Japanese Restaurant"
        )

        TagPill(
            text: "Really Long Restaurant Recommendation"
        )
    }
}
