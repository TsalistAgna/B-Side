//
//  AppTabBar.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI

enum AppTab {
    case home
    case collections
    case search
    case settings
}


struct AppTabBar: View {
    
    @Binding var selectedTab: AppTab
    
    var body: some View {
        
        HStack {
            
            tabButton(
                tab: .home,
                icon: "record.circle.fill",
                title: "Home"
            )
            
            tabButton(
                tab: .collections,
                icon: "archivebox.fill",
                title: "Collections"
            )
            
            tabButton(
                tab: .search,
                icon: "magnifyingglass",
                title: "Search"
            )
            
            tabButton(
                tab: .settings,
                icon: "gearshape.fill",
                title: "Settings"
            )
        }
        .padding(6)
        .background(
            .white
        )
        .clipShape(
            Capsule()
        )
        .shadow(
            color: .black.opacity(0.08),
            radius: 10,
            y: 3
        )
        .padding(.horizontal, 20)
    }
    
    
    private func tabButton(
        tab: AppTab,
        icon: String,
        title: String
    ) -> some View {
        
        let isSelected =
            selectedTab == tab
        
        return Button {
            
            selectedTab = tab
            
        } label: {
            
            VStack(spacing: 4) {
                
                Image(
                    systemName: icon
                )
                .font(
                    .system(size: 21)
                )
                
                Text(title)
                    .font(
                        .system(
                            size: 11,
                            weight: .medium
                        )
                    )
            }
            .foregroundStyle(
                isSelected
                    ? Color.bSideBlue
                    : Color.blue4
            )
            .frame(
                maxWidth: .infinity
            )
            .padding(.vertical, 8)
            .background {
                
                if isSelected {
                    
                    Capsule()
                        .fill(Color.blue1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
