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

            Text("Today’s Rediscovery")
                .font(
                    .title2.weight(.bold)
                )
                .foregroundStyle(
                    Color.textPrimary
                )


            ZStack {

                RoundedRectangle(
                    cornerRadius: 28
                )
                .fill(Color.decorativePink)


                if let image = track.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(16)
                        .accessibilityHidden(true)
                }
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
                    .body.weight(.semibold)
                )
                .foregroundStyle(Color.textPrimary)


                // MARK: Rediscovery Description

                Text(
                    track.rediscoveryDescription
                    ?? "Maybe this one is worth another look."
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    Color.textSecondary
                )
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 24)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
