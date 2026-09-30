//
//  CustomCollectionDetailView.swift
//  B-Side
//

import SwiftUI
import UIKit

struct CustomCollectionDetailView: View {
    let collectionID: UUID
    @ObservedObject var viewModel: HomeViewModel
    let onBack: () -> Void

    @State private var selectedTrack: Track?
    @State private var showTrackSelection = false
    @State private var showEditCollection = false
    @State private var showDeleteConfirmation = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private var collection: CustomCollection? {
        viewModel.customCollections.first { $0.id == collectionID }
    }

    private var collectionTracks: [Track] {
        collection.map(viewModel.tracks(in:)) ?? []
    }

    var body: some View {
        ZStack {
            Color.bSideBackground.ignoresSafeArea()

            if let collection {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        header(collection)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(collectionTracks) { track in
                                CustomLazyTrackCard(
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
        }
        .sheet(item: $selectedTrack) { track in
            TrackDetailSheet(track: track, viewModel: viewModel)
                .presentationDetents([.fraction(0.7), .large])
                .presentationCornerRadius(30)
        }
        .sheet(isPresented: $showTrackSelection) {
            if let collection {
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
        }
        .sheet(isPresented: $showEditCollection) {
            if let collection {
                EditCollectionSheet(
                    name: collection.name,
                    vinylStyle: collection.vinylStyle,
                    autoOrganize: collection.isAutoOrganized,
                    showsCustomOptions: true
                ) { name, vinylStyle, autoOrganize in
                    var updated = collection
                    updated.name = name
                    updated.vinylStyle = vinylStyle
                    updated.isAutoOrganized = autoOrganize
                    viewModel.updateCollection(updated)
                    if updated.isAutoOrganized {
                        Task { await viewModel.autoOrganize(collectionID: updated.id) }
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete this Custom Collection?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Collection", role: .destructive) {
                viewModel.deleteCollection(id: collectionID)
                onBack()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Tracks and original screenshots will remain in B-Side and Photos.")
        }
    }

    private func header(_ collection: CustomCollection) -> some View {
        ZStack {
            VStack(spacing: 4) {
                Text(collection.name)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.bSideDarkBlue)

                Text("\(collectionTracks.count) tracks")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.bSideSecondaryText)
            }

            HStack {
                CircleButton(icon: "chevron.left", action: onBack)
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

private struct CustomLazyTrackCard: View {
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
        Button { onSelect(displayedTrack) } label: {
            TrackCollectionCard(track: displayedTrack)
        }
        .buttonStyle(.plain)
        .task(id: track.id) {
            guard track.image == nil else { return }
            image = await loadImage(track.id)
        }
    }
}
