//
//  AddCollectionSheet.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 17/09/26.
//

import SwiftUI

struct AddCollectionSheet: View {

    @Environment(\.dismiss)
    private var dismiss

    @State private var collectionName = ""
    @State private var selectedVinyl: VinylStyle = .pink
    @State private var autoOrganize = true

    let onCreate: (
        String,
        VinylStyle,
        Bool
    ) -> Void

    var body: some View {

        ScrollView(
            showsIndicators: false
        ) {

            VStack(
                alignment: .leading,
                spacing: 28
            ) {

                Text("Add New Collection")
                    .font(
                        .title2.weight(.semibold)
                    )
                    .foregroundStyle(Color.textPrimary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .center
                    )


                // MARK: Collection Name

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    Text("Collection Name")
                        .font(
                            .subheadline.weight(.medium)
                        )
                        .foregroundStyle(Color.textPrimary)


                    TextField(
                        "Collection name",
                        text: $collectionName,
                        prompt: Text(
                            "e.g. Bali Food Trip"
                        )
                        .foregroundStyle(
                            Color.textTertiary
                        ),
                        axis: .vertical
                    )
                    .foregroundStyle(
                        Color.textPrimary
                    )
                    .padding()
                    .frame(minHeight: 58)
                    .background(
                        Color.bSideBackground
                    )
                    .overlay {

                        RoundedRectangle(
                            cornerRadius: 12
                        )
                        .stroke(
                            Color.borderDefault,
                            lineWidth: 1
                        )
                    }
                }


                // MARK: Vinyl

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text("Choose Vinyl")
                        .font(
                            .subheadline.weight(.medium)
                        )
                        .foregroundStyle(
                            Color.textPrimary
                        )


                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ],
                        spacing: 10
                    ) {

                        ForEach(
                            VinylStyle.allCases
                        ) { style in

                            Button {

                                selectedVinyl =
                                    style

                            } label: {

                                VinylOption(
                                    style: style,
                                    isSelected:
                                        selectedVinyl
                                        == style
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }


                Toggle(isOn: $autoOrganize) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Let AI Auto-Organize")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.textPrimary)

                        Text(
                            autoOrganize
                            ? "Side-B will find matching Tracks for this collection."
                            : "You'll choose existing Side-B Tracks next."
                        )
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    }
                }
                .tint(Color.accentPrimary)


                // MARK: Create

                Button {

                    createCollection()

                } label: {

                    Text("Create Collection")
                        .font(
                            .body.weight(.semibold)
                        )
                        .foregroundStyle(.white)
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(minHeight: BSideLayout.buttonMinimumHeight)
                        .background(
                            canCreate
                            ? Color.accentPrimary
                            : Color.controlDisabled
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: BSideLayout.buttonMinimumHeight / 2)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canCreate)
            }
            .padding(24)
        }
        .background(
            Color.bSideBackground
                .ignoresSafeArea()
        )
    }


    private var canCreate: Bool {

        !collectionName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
    }


    private func createCollection() {

        let cleanName =
            collectionName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard !cleanName.isEmpty else {
            return
        }


        onCreate(
            cleanName,
            selectedVinyl,
            autoOrganize
        )


        dismiss()
    }
}
