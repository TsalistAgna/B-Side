//
//  OnboardingTitle.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI

struct OnboardingTitle: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            Text("Turn your screenshots")
                .foregroundStyle(Color.bSideDarkBlue)

            HStack(spacing: 5) {
                Text("into")
                    .foregroundStyle(Color.bSideDarkBlue)

                Text("B-Sides.")
                    .foregroundStyle(Color.bSideBlue)
            }
        }
        .font(
            .system(
                size: 32,
                weight: .bold,
                design: .rounded
            )
        )
    }
}

#Preview {
    OnboardingTitle()
        .padding()
}
