//
//  BSideCollectionCard.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI

struct BSideCollectionCard: View {

    let collection: BSideCollection

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Spacer()


            HStack {

                Spacer()


                Image(
                    systemName: "opticaldisc"
                )
                .font(
                    .system(
                        size: 86,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    collection.category.accentColor
                )


                Spacer()
            }


            Spacer()


            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(
                    collection.category.title
                )
                .font(
                    .system(
                        size: 16,
                        weight: .medium
                    )
                )
                .foregroundStyle(Color.blue9)


                Text(
                    "\(collection.trackCount) tracks"
                )
                .font(
                    .system(size: 12)
                )
                .foregroundStyle(
                    Color.bSideSecondaryText
                )
            }
        }
        .padding(20)
        .frame(
            maxWidth: .infinity
        )
        .frame(height: 245)
        .background(
            Color.bSideBackground
        )
        .overlay {

            RoundedRectangle(
                cornerRadius: 16
            )
            .stroke(
                Color.blue4,
                lineWidth: 1
            )
        }
    }
}
