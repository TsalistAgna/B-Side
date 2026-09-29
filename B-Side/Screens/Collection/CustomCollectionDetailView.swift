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
                ManualTrackSelectionView(
                    collectionName: collection.name,
                    tracks: viewModel.processedLibraryTracks,
                    selectedIDs: Set(collection.trackIDs)
                ) { selectedIDs in
                    var updated = collection
                    updated.trackIDs = Array(selectedIDs)
                    viewModel.updateCollection(updated)
                }
            }
        }
        .sheet(isPresented: $showEditCollection) {
            if let collection {
                EditCustomCollectionSheet(collection: collection) { updated in
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
                    Button("Choose Tracks", systemImage: "checklist") {
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

private struct EditCustomCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let collection: CustomCollection
    let onSave: (CustomCollection) -> Void

    @State private var name: String
    @State private var vinylStyle: VinylStyle
    @State private var autoOrganize: Bool

    init(
        collection: CustomCollection,
        onSave: @escaping (CustomCollection) -> Void
    ) {
        self.collection = collection
        self.onSave = onSave
        _name = State(initialValue: collection.name)
        _vinylStyle = State(initialValue: collection.vinylStyle)
        _autoOrganize = State(initialValue: collection.isAutoOrganized)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Collection Name", text: $name)

                Picker("Vinyl Style", selection: $vinylStyle) {
                    ForEach(VinylStyle.allCases) { style in
                        Text(style.rawValue.capitalized).tag(style)
                    }
                }

                Toggle("Let AI Auto-Organize", isOn: $autoOrganize)
            }
            .navigationTitle("Edit Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = collection
                        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        updated.vinylStyle = vinylStyle
                        updated.isAutoOrganized = autoOrganize
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
