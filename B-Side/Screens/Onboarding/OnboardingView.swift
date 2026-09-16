//
//  OnboardingView.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI

struct OnboardingView: View {
    
    let onOrganizeTracks: () -> Void

    var body: some View {
        ZStack {

            Color.bSideBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - Title

                OnboardingTitle()
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(.top, 80)

                Spacer()
                    .frame(height: 35)

                // MARK: - Illustration

                Image("onboardingTurntable")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxWidth: 250,
                        maxHeight: 200
                    )

                Spacer()
                    .frame(height: 30)

                // MARK: - Description

                Text(
                    """
                    AI reads the meaning behind each Track and brings similar ones together into B-Sides. So nothing you saved gets lost in the shuffle.
                    """
                )
                .font(.system(size: 14))
                .foregroundStyle(Color.bSideSecondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

                Spacer()
                    .frame(height: 60)

                // MARK: - CTA

                PrimaryButton(
                    title: "Organize Tracks"
                ) {
                    onOrganizeTracks()
                }

                Spacer()
                    .frame(height: 20)

                PrivacyNote()

                Spacer()
                    .frame(height: 80)
            }
            .padding(.horizontal, 24)
        }
    }

    private func organizeTracks() {
        print("Organize Tracks tapped")
    }
}

#Preview {
    OnboardingView(onOrganizeTracks: {})
}
