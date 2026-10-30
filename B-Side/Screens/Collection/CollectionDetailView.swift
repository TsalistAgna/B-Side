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


    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 16),
            count: dynamicTypeSize >= .xxxLarge ? 1 : 2
        )
    }


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
            .presentationCornerRadius(BSideLayout.radiusSheet)
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
        .sheet(isPresented: $showDeleteConfirmation) {
            DestructiveConfirmationSheet(
                title: "Delete this Collection?",
                message: "Tracks will remain in Side-B and screenshots will remain in Photos.",
                destructiveButtonTitle: "Delete Collection"
            ) {
                viewModel.deleteAutomaticCollection(named: categoryName)
                onBack()
            }
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(BSideLayout.radiusSheet)
            .presentationDragIndicator(.visible)
        }
    }


    // MARK: - Header

    private var header: some View {
        VStack(spacing: BSideLayout.spacingSM) {
            HStack(alignment: .top, spacing: BSideLayout.spacingSM) {
                CircleButton(icon: "chevron.left", accessibilityLabel: "Back", action: onBack)
                if dynamicTypeSize.isAccessibilitySize {
                    Spacer()
                } else {
                    headerTitle
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
                headerTitle
            }
        }
    }

    private var headerTitle: some View {
        VStack(spacing: BSideLayout.spacingXS) {
            Text(categoryName)
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
