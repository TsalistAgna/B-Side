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
                    ? Color.bSideBlue
                    : Color.red4,
                lineWidth:
                    isSelected ? 2 : 1
            )


            Image(systemName: "opticaldisc")
                .font(
                    .system(size: 46)
                )
                .foregroundStyle(
                    style.color
                )
        }
        .frame(height: 105)
    }
}
