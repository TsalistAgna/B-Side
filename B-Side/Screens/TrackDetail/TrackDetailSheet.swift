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


    let track: Track

    @ObservedObject
    var viewModel: HomeViewModel


    @State
    private var isEditing = false

    @State
    private var showDeleteConfirmation = false


    @State
    private var editedTitle: String

    @State
    private var editedDescription: String

    @State
    private var editedTags: String

    @State
    private var editedCategory: BSideCategory


    init(
        track: Track,
        viewModel: HomeViewModel
    ) {

        self.track = track
        self.viewModel = viewModel


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

        _editedCategory = State(
            initialValue:
                track.category ?? .readLater
        )
    }


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
        .confirmationDialog(
            "Delete this Track?",
            isPresented:
                $showDeleteConfirmation,
            titleVisibility: .visible
        ) {

            Button(
                "Delete Track",
                role: .destructive
            ) {

                deleteTrack()
            }


            Button(
                "Cancel",
                role: .cancel
            ) {}
        } message: {

            Text(
                """
                This removes the Track from B-Side only.
                The original screenshot will stay in your Photos.
                """
            )
        }
    }


    // MARK: - Screenshot

    private var screenshot: some View {

        ZStack {

            RoundedRectangle(
                cornerRadius: 14
            )
            .fill(Color.blue1)


            Image(
                uiImage: track.image
            )
            .resizable()
            .scaledToFit()
            .padding(12)
        }
        .frame(height: 235)
    }


    // MARK: - Editable Content

    @ViewBuilder
    private var editableContent: some View {

        if isEditing {

            VStack(
                alignment: .leading,
                spacing: 14
            ) {

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
                .textFieldStyle(
                    .roundedBorder
                )


                TextEditor(
                    text:
                        $editedDescription
                )
                .font(
                    .system(size: 15)
                )
                .frame(
                    minHeight: 110
                )
                .padding(8)
                .background(
                    Color.blue1
                )
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
                    track.title ??
                    "Untitled Track"
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
                    track.detailDescription
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

            // Collection

            HStack {

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

                    Picker(
                        "Collection",
                        selection:
                            $editedCategory
                    ) {

                        ForEach(
                            BSideCategory.allCases,
                            id: \.self
                        ) { category in

                            Text(
                                category.title
                            )
                            .tag(category)
                        }
                    }

                } else {

                    TagPill(
                        text:
                            track.category?
                                .title
                            ?? "Unknown"
                    )
                }
            }


            // Tags

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
                    .textFieldStyle(
                        .roundedBorder
                    )

                } else {

                    TrackTagLayout(
                        tags: track.tags
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
                    .foregroundStyle(.white)
                    .frame(
                        maxWidth: .infinity
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

                    isEditing = true
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
                .foregroundStyle(.white)
                .frame(
                    maxWidth: .infinity
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


    // MARK: - Save

    private func saveChanges() {

        var updatedTrack = track


        updatedTrack.title =
            editedTitle


        updatedTrack.detailDescription =
            editedDescription


        updatedTrack.category =
            editedCategory


        updatedTrack.tags =
            editedTags
                .split(separator: ",")
                .map {
                    $0.trimmingCharacters(
                        in: .whitespaces
                    )
                }
                .filter {
                    !$0.isEmpty
                }


        viewModel.updateTrack(
            updatedTrack
        )


        isEditing = false
    }


    // MARK: - Delete

    private func deleteTrack() {

        viewModel.deleteTrackFromBSide(
            id: track.id
        )

        dismiss()
    }
}
