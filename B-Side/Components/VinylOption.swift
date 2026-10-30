//
//  VinylOption.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 17/09/26.
//

import SwiftUI

struct VinylOption: View {

    let style: VinylStyle
    let isSelected: Bool

    var body: some View {

        ZStack {

            RoundedRectangle(
                cornerRadius: 12
            )
            .fill(Color.bSideBackground)

            RoundedRectangle(
                cornerRadius: 12
            )
            .stroke(
                isSelected
                    ? Color.accentPrimary
                    : Color.decorativePink,
                lineWidth:
                    isSelected ? 2 : 1
            )


            Image(style.imageName)
                .resizable()
                .scaledToFit()
                .padding(14)
                .accessibilityHidden(true)
        }
        .frame(height: 105)
        .accessibilityElement()
        .accessibilityLabel("\(style.displayName) vinyl")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
