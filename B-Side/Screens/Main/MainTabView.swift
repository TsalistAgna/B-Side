//
//  MainTabView.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.scenePhase) private var scenePhase

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

                    SettingsView(
                        viewModel: viewModel
                    )
                }
            }


        }
        .safeAreaInset(edge: .top) {
            VStack(spacing: 4) {
                if viewModel.photosAccess == .limited {
                    Button("Limited Photos Access · Manage Photo Access") { viewModel.managePhotoAccess() }
                        .font(.footnote).padding(10).frame(minHeight: 44)
                } else if !viewModel.photosAccess.canRead && !viewModel.tracks.isEmpty {
                    Text(viewModel.photosAccess.title + ". Your saved Tracks are still available.")
                        .font(.footnote).padding(8)
                    Button("Manage Photos Access") { selectedTab = .settings }
                        .frame(minHeight: 44)
                }
            }
        }
        .alert("Changes weren’t saved", isPresented: Binding(get: { viewModel.trackSaveError != nil }, set: { if !$0 { viewModel.trackSaveError = nil } })) {
            Button("OK") { viewModel.trackSaveError = nil }
        } message: { Text(viewModel.trackSaveError ?? "") }
        .safeAreaInset(edge: .bottom) {
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
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await viewModel.refreshAccessiblePhotos() } }
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


#Preview {
    MainTabView()
}
