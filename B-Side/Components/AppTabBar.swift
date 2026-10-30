//
//  AppTabBar.swift
//  Side-B
//

import SwiftUI

enum AppTab {
    case home
    case collections
    case search
    case settings
}

struct AppTabBar: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Binding var selectedTab: AppTab

    var body: some View {
        HStack {
            tabButton(tab: .home, icon: "record.circle.fill", title: "Home")
            tabButton(tab: .collections, icon: "archivebox.fill", title: "Collections")
            tabButton(tab: .search, icon: "magnifyingglass", title: "Search")
            tabButton(tab: .settings, icon: "gearshape.fill", title: "Settings")
        }
        .padding(6)
        .background(Color.surfaceElevated)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
        .padding(.horizontal, 20)
    }

    private func tabButton(
        tab: AppTab,
        icon: String,
        title: LocalizedStringKey
    ) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: BSideLayout.spacingXS) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .accessibilityHidden(true)

                if !dynamicTypeSize.isAccessibilitySize {
                    Text(title)
                        .font(.caption2.weight(.medium))
                        .multilineTextAlignment(.center)
                }
            }
            .foregroundStyle(isSelected ? Color.accentText : Color.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .frame(minHeight: BSideLayout.minimumTouchTarget)
            .background {
                if isSelected {
                    Capsule().fill(Color.accentSoft)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(Text(title))
        .accessibilityShowsLargeContentViewer { Label(title, systemImage: icon) }
    }
}
