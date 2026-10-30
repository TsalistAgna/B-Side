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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 16),
            count: dynamicTypeSize >= .xxxLarge ? 1 : 2
        )
    }

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
                .presentationCornerRadius(BSideLayout.radiusSheet)
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
        .sheet(isPresented: $showDeleteConfirmation) {
            DestructiveConfirmationSheet(
                title: "Delete this Custom Collection?",
                message: "Tracks and original screenshots will remain in Side-B and Photos.",
                destructiveButtonTitle: "Delete Collection"
            ) {
                viewModel.deleteCollection(id: collectionID)
                onBack()
            }
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(BSideLayout.radiusSheet)
            .presentationDragIndicator(.visible)
        }
    }

    private func header(_ collection: CustomCollection) -> some View {
        VStack(spacing: BSideLayout.spacingSM) {
            HStack(alignment: .top, spacing: BSideLayout.spacingSM) {
                CircleButton(icon: "chevron.left", accessibilityLabel: "Back", action: onBack)
                if dynamicTypeSize.isAccessibilitySize {
                    Spacer()
                } else {
                    headerTitle(collection)
                }
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
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: BSideLayout.minimumTouchTarget, height: BSideLayout.minimumTouchTarget)
                    .background(Color.accentPrimary)
                    .clipShape(Circle())
                }
                .accessibilityLabel("Collection options")
            }
            .frame(minHeight: 58)
            if dynamicTypeSize.isAccessibilitySize {
                headerTitle(collection)
            }
        }
    }

    private func headerTitle(_ collection: CustomCollection) -> some View {
        VStack(spacing: BSideLayout.spacingXS) {
            Text(collection.name)
            .font(.title3.weight(.medium))
            .foregroundStyle(Color.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            Text("\(collectionTracks.count) tracks")
            .font(.footnote)
            .foregroundStyle(Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)

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
