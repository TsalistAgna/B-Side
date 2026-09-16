//
//  DailyFindingCard.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI

struct DailyFindingCard: View {

    let track: Track

    var body: some View {

        VStack(spacing: 16) {

            Text("Today’s Track Finding!")
                .font(
                    .system(
                        size: 24,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    Color.bSideDarkBlue
                )


            ZStack {

                RoundedRectangle(
                    cornerRadius: 28
                )
                .fill(Color.red4)


                Image(uiImage: track.image)
                    .resizable()
                    .scaledToFit()
                    .padding(16)
            }
            .frame(
                width: 170,
                height: 195
            )


            VStack(spacing: 6) {

                // MARK: Title

                Text(
                    track.title
                    ?? "A Track You Saved"
                )
                .font(
                    .system(
                        size: 17,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.primary)


                // MARK: Rediscovery Description

                Text(
                    track.rediscoveryDescription
                    ?? "Maybe this one is worth another look."
                )
                .font(
                    .system(size: 15)
                )
                .foregroundStyle(
                    Color.bSideSecondaryText
                )
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 24)
            }
        }
    }
}
