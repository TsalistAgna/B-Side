//
//  MainTabView.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI
import SwiftData

struct MainTabView: View {

    @Environment(\.modelContext)
    private var modelContext

    @StateObject
    private var viewModel =
        HomeViewModel()

    @State
    private var selectedTab:
        AppTab = .home

    @State
    private var selectedAutomaticCategoryName: String?

    @State
    private var selectedCustomCollectionID: UUID?


    var body: some View {

        ZStack(
            alignment: .bottom
        ) {

            Group {

                switch selectedTab {

                case .home:

                    HomeView(
                        viewModel:
                            viewModel
                    )


                case .collections:

                    if let categoryName = selectedAutomaticCategoryName {

                        CollectionDetailView(
                            categoryName:
                                categoryName,
                            viewModel:
                                viewModel,
                            onBack: {
                                selectedAutomaticCategoryName = nil
                            },
                            onRename: { name in
                                selectedAutomaticCategoryName = name
                            }
                        )

                    } else if let collectionID = selectedCustomCollectionID {

                        CustomCollectionDetailView(
                            collectionID: collectionID,
                            viewModel: viewModel,
                            onBack: {
                                selectedCustomCollectionID = nil
                            }
                        )

                    } else {

                        CollectionView(
                            viewModel:
                                viewModel,
                            onSelectAutomaticCollection: {
                                collection in

                                selectedAutomaticCategoryName = collection.name
                            },
                            onSelectCustomCollection: {
                                collection in

                                selectedCustomCollectionID = collection.id
                            }
                        )
                    }


                case .search:

                    SearchView(
                        viewModel: viewModel
                    )


                case .settings:

                    SettingsPlaceholderView()
                }
            }


            if selectedAutomaticCategoryName == nil &&
                selectedCustomCollectionID == nil {

                AppTabBar(
                    selectedTab:
                        $selectedTab
                )
                .padding(
                    .bottom,
                    8
                )
            }
        }
        .task {

            viewModel
                .configurePersistence(
                    context:
                        modelContext
                )


            await viewModel.prepare()
        }
    }
}


// MARK: - Temporary Settings Screen

private struct SettingsPlaceholderView:
    View {

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
