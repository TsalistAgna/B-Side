//
//  DeleteConfirmationSheet.swift
//  B-Side
//

import SwiftUI

struct DestructiveConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let icon: String?
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let destructiveButtonTitle: LocalizedStringKey
    let onConfirm: () -> Void

    init(
        icon: String? = "trash",
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        destructiveButtonTitle: LocalizedStringKey,
        onConfirm: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.destructiveButtonTitle = destructiveButtonTitle
        self.onConfirm = onConfirm
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.destructiveForeground)
                    .frame(width: 66, height: 66)
                    .background(Color.destructiveIconBackground)
                    .clipShape(Circle())
                    .accessibilityHidden(true)
            }

            DestructiveConfirmationContent(
                title: title,
                message: message
            )

            DestructiveConfirmationActions(
                destructiveButtonTitle: destructiveButtonTitle,
                onConfirm: {
                    onConfirm()
                    dismiss()
                },
                onCancel: dismiss.callAsFunction
            )
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .padding(.top, BSideLayout.spacingMD)
        .background(Color.bSideBackground.ignoresSafeArea())
    }
}

private struct DestructiveConfirmationContent: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.textPrimary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
    }
}

private struct DestructiveConfirmationActions: View {
    let destructiveButtonTitle: LocalizedStringKey
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onConfirm) {
                Text(destructiveButtonTitle)
                    .font(.headline)
                    .foregroundStyle(Color.destructiveForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(minHeight: BSideLayout.buttonMinimumHeight)
                    .background(Color.destructiveBackground)
                    .clipShape(RoundedRectangle(cornerRadius: BSideLayout.buttonMinimumHeight / 2))
            }
            .buttonStyle(.plain)

            Button(action: onCancel) {
                Text("Cancel")
                .font(.body.weight(.medium))
                .foregroundStyle(Color.accentText)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(minHeight: BSideLayout.minimumTouchTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
