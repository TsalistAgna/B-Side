//
//  MainTabView.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI

struct MainTabView: View {

    @StateObject
    private var viewModel = HomeViewModel()

    @State
    private var selectedTab: AppTab = .home
    
    @State
    private var selectedCollection: BSideCollection? = nil


    var body: some View {

        ZStack(alignment: .bottom) {

            Group {

                switch selectedTab {

                case .home:
                    HomeView(
                        viewModel: viewModel
                    )

                case .collections:

                    if let selectedCollection {

                        CollectionDetailView(
                            category:
                                selectedCollection.category,
                            viewModel:
                                viewModel,
                            onBack: {

                                self.selectedCollection =
                                    nil
                            }
                        )

                    } else {

                        CollectionView(
                            viewModel:
                                viewModel,
                            onSelectCollection: {
                                collection in

                                selectedCollection =
                                    collection
                            }
                        )
                    }

                case .search:
                    SearchPlaceholderView()

                case .settings:
                    SettingsPlaceholderView()
                }
            }


            if selectedCollection == nil {

                AppTabBar(
                    selectedTab:
                        $selectedTab
                )
                .padding(.bottom, 8)
            }
            
//            .padding(.bottom, 8)
        }
        .task {
            await viewModel.prepare()
        }
    }
}


// MARK: - Temporary Search Screen

private struct SearchPlaceholderView: View {

    var body: some View {

        ZStack {

            Color.bSideBackground
                .ignoresSafeArea()

            Text("Search")
        }
    }
}


// MARK: - Temporary Settings Screen

private struct SettingsPlaceholderView: View {

    var body: some View {

        ZStack {

            Color.bSideBackground
                .ignoresSafeArea()

            Text("Settings")
        }
    }
}


#Preview {
    MainTabView()
}
