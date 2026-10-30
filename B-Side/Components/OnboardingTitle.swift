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
                .foregroundStyle(Color.textPrimary)

            Text("into \(Text("Side-Bs.").foregroundStyle(Color.accentText))")
                .foregroundStyle(Color.textPrimary)

        }
        .font(
            .system(.largeTitle, design: .rounded).weight(.bold)
        )
    }
}

#Preview {
    OnboardingTitle()
        .padding()
}
