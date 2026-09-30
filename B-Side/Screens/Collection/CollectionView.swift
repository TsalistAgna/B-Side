//
//  CollectionView.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI

struct CollectionView: View {

    @ObservedObject
    var viewModel: HomeViewModel

    let onSelectAutomaticCollection:
        (BSideCollection) -> Void

    let onSelectCustomCollection:
        (CustomCollection) -> Void

    @State
    private var showAddCollection = false

    @State
    private var manualSelectionCollection: CustomCollection?

    @State
    private var pendingManualSelectionCollection: CustomCollection?

    private let columns = [

        GridItem(
            .flexible(),
            spacing: 16
        ),

        GridItem(
            .flexible(),
            spacing: 16
        )
    ]


    var body: some View {

        ZStack {

            Color.bSideBackground
                .ignoresSafeArea()


            collectionContent
        }
        .sheet(
            isPresented: $showAddCollection,
            onDismiss: {
                if let pendingManualSelectionCollection {
                    manualSelectionCollection = pendingManualSelectionCollection
                    self.pendingManualSelectionCollection = nil
                }
            }
        ) {

            AddCollectionSheet(
                onCreate: {
                    name,
                    vinylStyle,
                    autoOrganize in

                    createCollection(
                        name: name,
                        vinylStyle: vinylStyle,
                        autoOrganize: autoOrganize
                    )
                }
            )
            .presentationDetents([
                .fraction(0.62),
                .large
            ])
            .presentationCornerRadius(30)
        }
        .sheet(item: $manualSelectionCollection) { collection in
            TrackSelectionSheet(
                collection: collection,
                availableTracks: viewModel.processedLibraryTracks,
                loadImage: viewModel.image
            ) { trackIDs in
                viewModel.updateTracks(
                    for: collection.id,
                    trackIDs: trackIDs
                )
            }
        }
        .alert(
            "Couldn’t Organize Collection",
            isPresented: Binding(
                get: {
                    viewModel.collectionOrganizationError != nil
                },
                set: { isPresented in
                    if !isPresented {
                        viewModel.collectionOrganizationError = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                viewModel.collectionOrganizationError
                ?? "Please try again."
            )
        }
    }


    // MARK: - Content

    private var collectionContent: some View {

        ScrollView(
            showsIndicators: false
        ) {

            VStack(spacing: 24) {

                // MARK: Header

                header


                if hasCollections {

                    collectionGrid

                } else {

                    emptyView
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 36)

            // Space for bottom tab bar
            .padding(.bottom, 120)
        }
    }


    // MARK: - Collection Grid

    private var collectionGrid: some View {

        LazyVGrid(
            columns: columns,
            spacing: 16
        ) {

            Section {
                ForEach(viewModel.customCollections) { collection in

                Button {

                    onSelectCustomCollection(collection)

                } label: {

                    CustomCollectionCard(
                        collection: collection,
                        trackCount:
                            viewModel
                                .tracks(
                                    in: collection
                                )
                                .count
                    )
                    .overlay {
                        if viewModel.organizingCollectionIDs.contains(
                            collection.id
                        ) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)

                                ProgressView("Organizing…")
                                    .tint(Color.bSideBlue)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(
                    viewModel.organizingCollectionIDs.contains(
                        collection.id
                    )
                )
            }
            } header: {
                collectionSectionTitle("Custom Collections")
            }

            Section {
                ForEach(viewModel.collections) { collection in

                Button {

                    onSelectAutomaticCollection(
                        collection
                    )

                } label: {

                    BSideCollectionCard(
                        collection:
                            collection
                    )
                }
                .buttonStyle(.plain)
            }
            } header: {
                collectionSectionTitle("Automatic Collections")
            }
        }
    }


    // MARK: - Has Collections

    private var hasCollections: Bool {

        !viewModel.customCollections.isEmpty ||
        !viewModel.collections.isEmpty
    }


    // MARK: - Header

    private var header: some View {

        ZStack {

            Text("B-Side Collection")
                .font(
                    .system(
                        size: 20,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    Color.bSideDarkBlue
                )


            HStack {

                Spacer()


                Button {

                    showAddCollection = true

                } label: {

                    Image(
                        systemName: "plus"
                    )
                    .font(
                        .system(
                            size: 22,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(.white)
                    .frame(
                        width: 42,
                        height: 42
                    )
                    .background(
                        Color.bSideBlue
                    )
                    .clipShape(
                        Circle()
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 42)
    }


    // MARK: - Empty View

    private var emptyView: some View {

        VStack(spacing: 14) {

            Image(
                systemName: "opticaldisc"
            )
            .font(
                .system(size: 54)
            )
            .foregroundStyle(
                Color.blue3
            )
            .padding(.top, 80)


            Text("No B-Sides yet")
                .font(
                    .system(
                        size: 24,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    Color.bSideDarkBlue
                )


            Text(
                viewModel.isAnalyzing
                ? "B-Side is organizing your tracks..."
                : "Your organized screenshots will appear here."
            )
            .font(
                .system(size: 15)
            )
            .foregroundStyle(
                Color.bSideSecondaryText
            )
            .multilineTextAlignment(
                .center
            )


            if viewModel.isAnalyzing {

                ProgressView()
                    .padding(.top, 8)
            }
        }
        .frame(
            maxWidth: .infinity
        )
    }


    // MARK: - Create Collection

    private func createCollection(
        name: String,
        vinylStyle: VinylStyle,
        autoOrganize: Bool
    ) {

        let collection =
            viewModel.createCollection(
                name: name,
                vinylStyle: vinylStyle,
                autoOrganize: autoOrganize
            )


        if autoOrganize {
            Task {
                await viewModel.autoOrganize(collectionID: collection.id)
            }
        } else {
            pendingManualSelectionCollection = collection
        }
    }

    private func collectionSectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Color.bSideDarkBlue)
            .frame(maxWidth: .infinity, alignment: .leading)
            .gridCellColumns(2)
    }
}


#Preview {

    CollectionView(
        viewModel:
            HomeViewModel(),
        onSelectAutomaticCollection: { _ in },
        onSelectCustomCollection: { _ in }
    )
}
