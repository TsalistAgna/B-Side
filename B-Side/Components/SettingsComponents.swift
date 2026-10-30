//
//  SettingsComponents.swift
//  Side-B
//

import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BSideLayout.spacingSM) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                content
            }
            .background(Color.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: BSideLayout.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: BSideLayout.radiusMedium)
                    .stroke(Color.borderDefault, lineWidth: 1)
            }
        }
    }
}

struct SettingsNavigationRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let icon: String
    let title: String
    var subtitle: String?
    var detail: String?
    var trailingSystemImage = "chevron.right"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 13) {
                if !dynamicTypeSize.isAccessibilitySize {
                    SettingsIcon(symbol: icon)
                }

                VStack(alignment: .leading, spacing: BSideLayout.spacingXS) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    if dynamicTypeSize.isAccessibilitySize, let detail {
                        Text(detail)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 10)

                if !dynamicTypeSize.isAccessibilitySize, let detail {
                    Text(detail)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.trailing)
                }

                Image(systemName: trailingSystemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, BSideLayout.radiusMedium)
            .padding(.vertical, 14)
            .frame(minHeight: BSideLayout.minimumTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(
            trailingSystemImage == "arrow.up.right.square"
                ? "Opens the Side-B privacy policy website."
                : ""
        )
    }
}

struct SettingsToggleRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibilityLayout
            } else {
                regularLayout
            }
        }
        .padding(.horizontal, BSideLayout.radiusMedium)
        .padding(.vertical, 14)
    }

    private var regularLayout: some View {
        HStack(alignment: .center, spacing: 13) {
            SettingsIcon(symbol: icon)
            textContent.accessibilityHidden(true)
            Spacer(minLength: 12)
            settingToggle
        }
    }

    private var accessibilityLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 13) {
                textContent.accessibilityHidden(true)
            }
            settingToggle
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: BSideLayout.spacingXS) {
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var settingToggle: some View {
        Toggle(title, isOn: $isOn)
            .labelsHidden()
            .toggleStyle(BSideToggleStyle())
            .frame(minWidth: BSideLayout.minimumTouchTarget, minHeight: BSideLayout.minimumTouchTarget)
            .accessibilityLabel(title)
            .accessibilityHint(subtitle)
    }
}

struct SettingsDivider: View {
    var body: some View {
        Divider()
            .overlay(Color.divider)
            .padding(.leading, 61)
    }
}

private struct SettingsIcon: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(Color.accentText)
            .frame(minWidth: 32, minHeight: 32)
            .background(Color.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .accessibilityHidden(true)
    }
}
