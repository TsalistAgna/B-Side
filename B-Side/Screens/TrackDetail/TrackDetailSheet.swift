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
    @State private var imageLoadFinished = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

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


                Text(viewModel.analysisStatus(for: currentTrack.id) == .completed ? "AI understood this as" : "Track details")
                    .font(
                        .footnote
                    )
                    .foregroundStyle(
                        Color.textSecondary
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
            imageLoadFinished = true
        }
        .fullScreenCover(
            isPresented: $showFullScreenshot
        ) {

            if let image = currentTrack.image {
                FullScreenScreenshotView(image: image, accessibilityDescription: currentTrack.detailDescription ?? currentTrack.title ?? "Screenshot")
            }
        }
        .sheet(isPresented: $showDeleteConfirmation) {
            DestructiveConfirmationSheet(
                title: "Delete this Track?",
                message: "This removes the Track from Side-B only. The original screenshot will stay in your Photos.",
                destructiveButtonTitle: "Delete Track",
                onConfirm: deleteTrack
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(BSideLayout.radiusSheet)
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
                    Color.surfaceSecondary
                )


                if let image = currentTrack.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                } else if imageLoadFinished {
                    Text("Original screenshot isn’t currently accessible.")
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ProgressView().tint(Color.accentPrimary)
                }
            }
            .frame(minHeight: 235)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(currentTrack.image == nil && imageLoadFinished ? "Original screenshot isn’t currently accessible." : "View full screenshot")
        .disabled(currentTrack.image == nil)
    }

    private var metadataLayout: AnyLayout {
        dynamicTypeSize >= .xxxLarge
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .top))
    }

    private var actionLayout: AnyLayout {
        dynamicTypeSize >= .xxxLarge
            ? AnyLayout(VStackLayout(spacing: 16))
            : AnyLayout(HStackLayout(spacing: 16))
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
                    text: $editedTitle, axis: .vertical
                )
                .font(
                    .headline.weight(.semibold)
                )
                .foregroundStyle(
                    Color.textPrimary
                )
                .padding(.horizontal, 12)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(minHeight: BSideLayout.buttonMinimumHeight)
                .background(
                    Color.surfaceSecondary
                )
                .overlay {

                    RoundedRectangle(
                        cornerRadius: 10
                    )
                    .stroke(
                        Color.borderDefault,
                        lineWidth: 1
                    )
                }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 10
                    )
                )


                // MARK: Description

                TextField("Track description", text: $editedDescription, axis: .vertical)
                .accessibilityLabel("Track description")
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    Color.textPrimary
                )
                .scrollContentBackground(
                    .hidden
                )
                .frame(
                    minHeight: 110
                )
                .padding(8)
                .background(
                    Color.surfaceSecondary
                )
                .overlay {

                    RoundedRectangle(
                        cornerRadius: 10
                    )
                    .stroke(
                        Color.borderDefault,
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
                    .headline.weight(.semibold)
                )
                .foregroundStyle(
                    Color.textPrimary
                )


                Text(
                    currentTrack
                        .detailDescription
                    ?? "No description available."
                )
                .font(
                    .subheadline
                )
                .foregroundStyle(
                    Color.textPrimary
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

            metadataLayout {

                Text("Collection")
                    .font(
                        .footnote.weight(.semibold)
                    )
                    .foregroundStyle(
                        Color.textPrimary
                    )
                    .frame(width: dynamicTypeSize >= .xxxLarge ? nil : 80, alignment: .leading)


                if isEditing {

                    TextField(
                        "Collection name",
                        text:
                            $editedCategoryName, axis: .vertical
                    )
                    .font(
                        .footnote
                    )
                    .foregroundStyle(
                        Color.textPrimary
                    )
                    .padding(
                        .horizontal,
                        10
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: BSideLayout.buttonMinimumHeight)
                    .background(
                        Color.surfaceSecondary
                    )
                    .overlay {

                        RoundedRectangle(
                            cornerRadius: 8
                        )
                        .stroke(
                            Color.borderDefault,
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

            metadataLayout {

                Text("Tags")
                    .font(
                        .footnote.weight(.semibold)
                    )
                    .foregroundStyle(
                        Color.textPrimary
                    )
                    .frame(width: dynamicTypeSize >= .xxxLarge ? nil : 80, alignment: .leading)


                if isEditing {

                    TextField(
                        "Udon, Restaurant",
                        text:
                            $editedTags, axis: .vertical
                    )
                    .font(
                        .footnote
                    )
                    .foregroundStyle(
                        Color.textPrimary
                    )
                    .padding(
                        .horizontal,
                        10
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: BSideLayout.buttonMinimumHeight)
                    .background(
                        Color.surfaceSecondary
                    )
                    .overlay {

                        RoundedRectangle(
                            cornerRadius: 8
                        )
                        .stroke(
                            Color.borderDefault,
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

        actionLayout {

            Button {

                showDeleteConfirmation =
                    true

            } label: {

                Text("Delete Track")
                    .font(
                        .subheadline.weight(.semibold)
                    )
                    .foregroundStyle(Color.destructiveForeground)
                    .frame(
                        maxWidth:
                            .infinity
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: BSideLayout.buttonMinimumHeight)
                    .background(
                        Color.destructiveBackground
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: BSideLayout.buttonMinimumHeight / 2)
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
                    .subheadline.weight(.semibold)
                )
                .foregroundStyle(
                    .white
                )
                .frame(
                    maxWidth:
                        .infinity
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(minHeight: BSideLayout.buttonMinimumHeight)
                .background(
                    Color.accentPrimary
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: BSideLayout.buttonMinimumHeight / 2)
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
            ? nil
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


        guard viewModel.trackSaveError == nil else { return }
        // Update sheet only after saving succeeded.
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
