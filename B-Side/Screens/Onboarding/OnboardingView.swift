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

            ScrollView {
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
                    .accessibilityHidden(true)
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
                    Turn saved screenshots into organized collections. Tracks are screenshots saved in Side-B. On supported devices, Apple Intelligence helps you organize them on-device. Your original screenshots stay in Photos.
                    """
                )
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

                Spacer()
                    .frame(height: 60)

                // MARK: - CTA

                PrimaryButton(
                    title: "Get Started"
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
    }


}

#Preview {
    OnboardingView(onOrganizeTracks: {})
}
