//
//  TrackDetailSheet.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 16/09/26.
//

//This handles:
//normal display
//Edit Track
//Save Changes
//editable title
//editable description
//editable tags
//editable collection/category
//delete confirmation

import SwiftUI

struct TrackDetailSheet: View {

    @Environment(\.dismiss)
    private var dismiss


    // MARK: - Data

    @ObservedObject
    var viewModel: HomeViewModel

    @State
    private var currentTrack: Track


    // MARK: - UI State

    @State
    private var showFullScreenshot = false

    @State
    private var isEditing = false

    @State
    private var showDeleteConfirmation = false


    // MARK: - Editable Values

    @State
    private var editedTitle: String

    @State
    private var editedDescription: String

    @State
    private var editedTags: String

    @State
    private var editedCategoryName: String


    // MARK: - Init

    init(
        track: Track,
        viewModel: HomeViewModel
    ) {

        self.viewModel = viewModel

        _currentTrack = State(
            initialValue: track
        )

        _editedTitle = State(
            initialValue:
                track.title ?? ""
        )

        _editedDescription = State(
            initialValue:
                track.detailDescription ?? ""
        )

        _editedTags = State(
            initialValue:
                track.tags.joined(
                    separator: ", "
                )
        )

        _editedCategoryName = State(
            initialValue:
                track.categoryName ?? ""
        )
    }


    // MARK: - Body

    var body: some View {

        ScrollView(
            showsIndicators: false
        ) {

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                screenshot


                Text("AI understood this as")
                    .font(
                        .system(size: 13)
                    )
                    .foregroundStyle(
                        Color.bSideSecondaryText
                    )


                editableContent


                metadata


                actionButtons
            }
            .padding(20)
            .padding(.bottom, 20)
        }
        .background(
            Color.bSideBackground
                .ignoresSafeArea()
        )
        .task(id: currentTrack.id) {
            guard currentTrack.image == nil else { return }
            currentTrack.image = await viewModel.image(for: currentTrack.id)
        }
        .fullScreenCover(
            isPresented: $showFullScreenshot
        ) {

            if let image = currentTrack.image {
                FullScreenScreenshotView(image: image)
            }
        }
        .sheet(isPresented: $showDeleteConfirmation) {
            DeleteConfirmationSheet(
                title: "Delete this Track?",
                message: "This removes the Track from B-Side only. The original screenshot will stay in your Photos.",
                deleteButtonTitle: "Delete Track",
                onDelete: deleteTrack
            )
            .presentationDetents([.height(390)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(30)
        }
    }


    // MARK: - Screenshot

    private var screenshot: some View {

        Button {

            showFullScreenshot = true

        } label: {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 14
                )
                .fill(
                    Color.blue1
                )


                if let image = currentTrack.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                } else {
                    ProgressView()
                        .tint(Color.bSideBlue)
                }
            }
            .frame(height: 235)
        }
        .buttonStyle(.plain)
    }


    // MARK: - Editable Content

    @ViewBuilder
    private var editableContent: some View {

        if isEditing {

            VStack(
                alignment: .leading,
                spacing: 14
            ) {

                // MARK: Title

                TextField(
                    "Track title",
                    text: $editedTitle
                )
                .font(
                    .system(
                        size: 18,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.blue10
                )
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(
                    Color.blue1
                )
                .overlay {

                    RoundedRectangle(
                        cornerRadius: 10
                    )
                    .stroke(
                        Color.blue4,
                        lineWidth: 1
                    )
                }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 10
                    )
                )


                // MARK: Description

                TextEditor(
                    text:
                        $editedDescription
                )
                .font(
                    .system(size: 15)
                )
                .foregroundStyle(
                    Color.blue10
                )
                .scrollContentBackground(
                    .hidden
                )
                .frame(
                    minHeight: 110
                )
                .padding(8)
                .background(
                    Color.blue1
                )
                .overlay {

                    RoundedRectangle(
                        cornerRadius: 10
                    )
                    .stroke(
                        Color.blue4,
                        lineWidth: 1
                    )
                }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 10
                    )
                )
            }

        } else {

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text(
                    currentTrack.title
                    ?? "Untitled Track"
                )
                .font(
                    .system(
                        size: 18,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.blue10
                )


                Text(
                    currentTrack
                        .detailDescription
                    ?? "No description available."
                )
                .font(
                    .system(size: 15)
                )
                .foregroundStyle(
                    Color.blue10
                )
                .lineSpacing(3)
            }
        }
    }


    // MARK: - Metadata

    private var metadata: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            // MARK: Collection / Category

            HStack(
                alignment: .top
            ) {

                Text("Collection")
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        Color.blue10
                    )
                    .frame(
                        width: 80,
                        alignment: .leading
                    )


                if isEditing {

                    TextField(
                        "Collection name",
                        text:
                            $editedCategoryName
                    )
                    .font(
                        .system(size: 13)
                    )
                    .foregroundStyle(
                        Color.blue10
                    )
                    .padding(
                        .horizontal,
                        10
                    )
                    .frame(height: 38)
                    .background(
                        Color.blue1
                    )
                    .overlay {

                        RoundedRectangle(
                            cornerRadius: 8
                        )
                        .stroke(
                            Color.blue4,
                            lineWidth: 1
                        )
                    }
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 8
                        )
                    )

                } else {

                    TagPill(
                        text:
                            currentTrack
                                .categoryName
                            ?? "Uncategorized"
                    )
                }
            }


            // MARK: Tags

            HStack(
                alignment: .top
            ) {

                Text("Tags")
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        Color.blue10
                    )
                    .frame(
                        width: 80,
                        alignment: .leading
                    )


                if isEditing {

                    TextField(
                        "Udon, Restaurant",
                        text:
                            $editedTags
                    )
                    .font(
                        .system(size: 13)
                    )
                    .foregroundStyle(
                        Color.blue10
                    )
                    .padding(
                        .horizontal,
                        10
                    )
                    .frame(height: 38)
                    .background(
                        Color.blue1
                    )
                    .overlay {

                        RoundedRectangle(
                            cornerRadius: 8
                        )
                        .stroke(
                            Color.blue4,
                            lineWidth: 1
                        )
                    }
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 8
                        )
                    )

                } else {

                    TrackTagLayout(
                        tags:
                            currentTrack.tags
                    )
                }
            }
        }
    }


    // MARK: - Buttons

    private var actionButtons: some View {

        HStack(spacing: 16) {

            Button {

                showDeleteConfirmation =
                    true

            } label: {

                Text("Delete Track")
                    .font(
                        .system(
                            size: 15,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        .white
                    )
                    .frame(
                        maxWidth:
                            .infinity
                    )
                    .frame(height: 48)
                    .background(
                        Color.gray
                    )
                    .clipShape(
                        Capsule()
                    )
            }


            Button {

                if isEditing {

                    saveChanges()

                } else {

                    beginEditing()
                }

            } label: {

                Text(
                    isEditing
                    ? "Save Changes"
                    : "Edit Track"
                )
                .font(
                    .system(
                        size: 15,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    .white
                )
                .frame(
                    maxWidth:
                        .infinity
                )
                .frame(height: 48)
                .background(
                    Color.bSideBlue
                )
                .clipShape(
                    Capsule()
                )
            }
        }
    }


    // MARK: - Begin Editing

    private func beginEditing() {

        // Always use the newest Track values
        // when entering edit mode.

        editedTitle =
            currentTrack.title ?? ""

        editedDescription =
            currentTrack
                .detailDescription
            ?? ""

        editedTags =
            currentTrack.tags.joined(
                separator: ", "
            )

        editedCategoryName =
            currentTrack
                .categoryName
            ?? ""


        isEditing = true
    }


    // MARK: - Save

    private func saveChanges() {

        let cleanTitle =
            editedTitle
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        let cleanCategory =
            editedCategoryName
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        var updatedTrack =
            currentTrack


        updatedTrack.title =
            cleanTitle.isEmpty
            ? "Untitled Track"
            : cleanTitle


        updatedTrack.detailDescription =
            editedDescription
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )


        updatedTrack.categoryName =
            cleanCategory.isEmpty
            ? "Uncategorized"
            : cleanCategory


        updatedTrack.tags =
            editedTags
                .split(
                    separator: ","
                )
                .map {

                    $0.trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
                }
                .filter {

                    !$0.isEmpty
                }


        // Update shared ViewModel + SwiftData
        viewModel.updateTrack(
            updatedTrack
        )


        // Update sheet immediately
        currentTrack =
            updatedTrack


        isEditing = false
    }


    // MARK: - Delete

    private func deleteTrack() {

        viewModel
            .deleteTrackFromBSide(
                id:
                    currentTrack.id
            )


        dismiss()
    }
}
