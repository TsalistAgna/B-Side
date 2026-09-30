//
//  CollectionDetailView.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 16/09/26.
//

import SwiftUI
import UIKit

struct CollectionDetailView: View {

    let categoryName: String

    @ObservedObject
    var viewModel: HomeViewModel

    let onBack: () -> Void

    let onRename: (String) -> Void


    @State
    private var selectedTrack: Track?

    @State private var showTrackSelection = false
    @State private var showEditCollection = false
    @State private var showDeleteConfirmation = false


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


    private var collectionTracks: [Track] {

        viewModel.tracks(
            inCategory: categoryName
        )
    }


    var body: some View {

        ZStack {

            Color.bSideBackground
                .ignoresSafeArea()


            ScrollView(
                showsIndicators: false
            ) {

                VStack(spacing: 22) {

                    header


                    LazyVGrid(
                        columns: columns,
                        spacing: 16
                    ) {

                        ForEach(
                            collectionTracks
                        ) { track in

                            LazyTrackCollectionCard(
                                track: track,
                                loadImage: viewModel.image,
                                onSelect: { selectedTrack = $0 }
                            )
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .sheet(
            item: $selectedTrack
        ) { track in

            TrackDetailSheet(
                track: track,
                viewModel: viewModel
            )
            .presentationDetents([
                .fraction(0.7),
                .large
            ])
            .presentationDragIndicator(
                .hidden
            )
            .presentationCornerRadius(30)
        }
        .sheet(isPresented: $showTrackSelection) {
            TrackSelectionSheet(
                collectionName: categoryName,
                selectedTrackIDs: Set(collectionTracks.map(\.id)),
                availableTracks: viewModel.processedLibraryTracks,
                loadImage: viewModel.image
            ) { trackIDs in
                viewModel.updateTracks(
                    inCategory: categoryName,
                    trackIDs: trackIDs
                )
            }
        }
        .sheet(isPresented: $showEditCollection) {
            EditCollectionSheet(
                name: categoryName,
                showsCustomOptions: false
            ) { name, _, _ in
                viewModel.renameAutomaticCollection(
                    from: categoryName,
                    to: name
                )
                onRename(name)
            }
        }
        .confirmationDialog(
            "Delete this Collection?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Collection", role: .destructive) {
                viewModel.deleteAutomaticCollection(named: categoryName)
                onBack()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Tracks will remain in B-Side and screenshots will remain in Photos.")
        }
    }


    // MARK: - Header

    private var header: some View {

        ZStack {

            VStack(spacing: 4) {

                Text(categoryName)
                    .font(
                        .system(
                            size: 20,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        Color.bSideDarkBlue
                    )


                Text(
                    "\(collectionTracks.count) tracks"
                )
                .font(
                    .system(size: 13)
                )
                .foregroundStyle(
                    Color.bSideSecondaryText
                )
            }


            HStack {

                CircleButton(
                    icon: "chevron.left"
                ) {
                    onBack()
                }

                Spacer()

                Menu {
                    Button("Add Tracks", systemImage: "plus") {
                        showTrackSelection = true
                    }
                    Button("Edit Collection", systemImage: "pencil") {
                        showEditCollection = true
                    }
                    Button("Delete Collection", systemImage: "trash", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.bSideBlue)
                        .clipShape(Circle())
                }
            }
        }
        .frame(height: 58)
    }
}

private struct LazyTrackCollectionCard: View {
    let track: Track
    let loadImage: (String) async -> UIImage?
    let onSelect: (Track) -> Void

    @State private var image: UIImage?

    private var displayedTrack: Track {
        var value = track
        value.image = image ?? track.image
        return value
    }

    var body: some View {
        Button {
            onSelect(displayedTrack)
        } label: {
            TrackCollectionCard(track: displayedTrack)
        }
        .buttonStyle(.plain)
        .task(id: track.id) {
            guard track.image == nil else { return }
            image = await loadImage(track.id)
        }
    }
}
