//
//  CircleButton.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 16/09/26.
//

import SwiftUI

struct CircleButton: View {

    let icon: String
    let accessibilityLabel: LocalizedStringKey
    let action: () -> Void


    var body: some View {

        Button {
            action()
        } label: {

            Image(
                systemName: icon
            )
            .font(
                .system(
                    size: 22,
                    weight: .medium
                )
            )
            .foregroundStyle(.white)
            .frame(
                width: BSideLayout.minimumTouchTarget,
                height: BSideLayout.minimumTouchTarget
            )
            .background(
                Color.bSideBlue
            )
            .clipShape(
                Circle()
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
