//
//  OnDeviceAIInfoSheet.swift
//  B-Side
//

import SwiftUI

struct OnDeviceAIInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        BSideInfoSheet(
            icon: "cpu",
            title: "On-Device AI",
            buttonTitle: "Done"
        ) {
            VStack(alignment: .leading, spacing: 18) {
                Text(
                    "Side-B uses Apple Foundation Models to understand your screenshots and generate useful Track metadata. Analysis is designed to happen on your device."
                )

                Text("Side-B uses this information to create:")
                    .fontWeight(.medium)
                    .foregroundStyle(Color.textPrimary)

                VStack(alignment: .leading, spacing: 10) {
                    infoItem("Track titles")
                    infoItem("Descriptions")
                    infoItem("Tags")
                    infoItem("Side-B collections")
                    infoItem("Rediscovery messages")
                }

                Text("Your original screenshot remains in Photos.")
                    .fontWeight(.medium)
                    .foregroundStyle(Color.textPrimary)
            }
            .font(.subheadline)
            .foregroundStyle(Color.textSecondary)
            .lineSpacing(3)
        } action: {
            dismiss()
        }
    }

    private func infoItem(_ text: String) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.accentPrimary)
                .frame(width: 6, height: 6)

            Text(text)
        }
    }
}

struct BSideInfoSheet<Content: View>: View {
    let icon: String
    let title: String
    let buttonTitle: String
    @ViewBuilder let content: Content
    let action: () -> Void

    init(
        icon: String,
        title: String,
        buttonTitle: String,
        @ViewBuilder content: () -> Content,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.buttonTitle = buttonTitle
        self.content = content()
        self.action = action
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.accentText)
                    .frame(width: 64, height: 64)
                    .background(Color.surfaceSecondary)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                content
                    .frame(maxWidth: .infinity, alignment: .leading)

                PrimaryButton(
                    title: buttonTitle,
                    action: action
                )
            }
            .padding(24)
        }
        .padding(.top, BSideLayout.spacingMD)
        .background(Color.bSideBackground.ignoresSafeArea())
    }
}
