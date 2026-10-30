//
//  TrackSelectionSheet.swift
//  B-Side
//

import SwiftUI
import UIKit

struct TrackSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let collectionName: String
    let availableTracks: [Track]
    let loadImage: (String) async -> UIImage?
    let onSave: ([String]) -> Void

    @State private var selectedTrackIDs: Set<String>

    private let initialTrackIDs: Set<String>

    init(
        collection: CustomCollection,
        availableTracks: [Track],
        loadImage: @escaping (String) async -> UIImage?,
        onSave: @escaping ([String]) -> Void
    ) {
        collectionName = collection.name
        self.availableTracks = availableTracks
        self.loadImage = loadImage
        self.onSave = onSave

        let initialIDs = Set(collection.trackIDs)
        initialTrackIDs = initialIDs
        _selectedTrackIDs = State(initialValue: initialIDs)
    }

    init(
        collectionName: String,
        selectedTrackIDs: Set<String>,
        availableTracks: [Track],
        loadImage: @escaping (String) async -> UIImage?,
        onSave: @escaping ([String]) -> Void
    ) {
        self.collectionName = collectionName
        self.availableTracks = availableTracks
        self.loadImage = loadImage
        self.onSave = onSave
        initialTrackIDs = selectedTrackIDs
        _selectedTrackIDs = State(initialValue: selectedTrackIDs)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bSideBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(availableTracks) { track in
                            TrackSelectionRow(
                                track: track,
                                isSelected: selectedTrackIDs.contains(track.id),
                                loadImage: loadImage
                            ) {
                                toggle(track.id)
                            }

                            Divider()
                                .overlay(Color.divider)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 90)
                }
            }
            .navigationTitle(collectionName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    onSave(Array(selectedTrackIDs))
                    dismiss()
                } label: {
                    Text("Save Tracks")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(minHeight: BSideLayout.buttonMinimumHeight)
                        .background(
                            hasChanges
                            ? Color.accentPrimary
                            : Color.controlDisabled
                        )
                        .clipShape(RoundedRectangle(cornerRadius: BSideLayout.buttonMinimumHeight / 2))
                }
                .buttonStyle(.plain)
                .disabled(!hasChanges)
                .padding(.horizontal, 22)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.bSideBackground)
            }
        }
    }

    private var hasChanges: Bool {
        selectedTrackIDs != initialTrackIDs
    }

    private func toggle(_ trackID: String) {
        if selectedTrackIDs.contains(trackID) {
            selectedTrackIDs.remove(trackID)
        } else {
            selectedTrackIDs.insert(trackID)
        }
    }
}

private struct TrackSelectionRow: View {
    let track: Track
    let isSelected: Bool
    let loadImage: (String) async -> UIImage?
    let onToggle: () -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                thumbnailView
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(track.title ?? "Untitled Track")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.textPrimary)

                    if let categoryName = track.categoryName {
                        Text(categoryName)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Spacer()

                Image(
                    systemName: isSelected
                    ? "checkmark.circle.fill"
                    : "circle"
                )
                .font(.system(size: 23))
                .accessibilityHidden(true)
                .foregroundStyle(Color.accentText)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .task(id: track.id) {
            if let image = track.image {
                thumbnail = image
            } else {
                thumbnail = await loadImage(track.id)
            }
        }
    }

    private var thumbnailView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.surfaceSecondary)

            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                ProgressView()
                    .tint(Color.accentPrimary)
            }
        }
        .frame(width: 58, height: 74)
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}
