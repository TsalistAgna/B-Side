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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 16),
            count: dynamicTypeSize >= .xxxLarge ? 1 : 2
        )
    }


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
            .presentationCornerRadius(BSideLayout.radiusSheet)
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
            .padding(.top, 24)

            // Space for bottom tab bar
            .padding(.bottom, BSideLayout.spacingXL)
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
                                    .tint(Color.accentPrimary)
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

        HStack {

            Text("Side-B Collection")
                .font(
                    .largeTitle.weight(.bold)
                )
                .foregroundStyle(
                    Color.textPrimary
                )

            Spacer()

            CircleButton(
                icon: "plus",
                accessibilityLabel: "Add collection"
            ) {
                showAddCollection = true
            }
        }
        .frame(minHeight: 42)
    }


    // MARK: - Empty View

    private var emptyView: some View {

        VStack(spacing: 14) {

            Image(
                systemName: "opticaldisc"
            )
            .accessibilityHidden(true)
            .font(
                .system(size: 54)
            )
            .foregroundStyle(
                Color.decorativeAccent
            )
            .padding(.top, 80)


            Text("No Collections Yet")
                .font(
                    .title2.weight(.bold)
                )
                .foregroundStyle(
                    Color.textPrimary
                )


            Text(
                viewModel.isAnalyzing
                ? "Side-B is organizing your tracks..."
                : "Side-B will group similar screenshots here, or you can create a collection yourself."
            )
            .font(
                .subheadline
            )
            .foregroundStyle(
                Color.textSecondary
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
            .font(.callout.weight(.semibold))
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .gridCellColumns(dynamicTypeSize >= .xxxLarge ? 1 : 2)
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
