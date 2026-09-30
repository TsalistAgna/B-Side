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
                        .system(
                            size: 22,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(Color.blue10)
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
                            .system(
                                size: 15,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(Color.blue10)


                    TextField(
                        "",
                        text: $collectionName,
                        prompt: Text(
                            "e.g. Bali Food Trip"
                        )
                        .foregroundStyle(
                            Color.blue3
                        )
                    )
                    .foregroundStyle(
                        Color.blue10
                    )
                    .padding()
                    .frame(height: 58)
                    .background(
                        Color.bSideBackground
                    )
                    .overlay {

                        RoundedRectangle(
                            cornerRadius: 12
                        )
                        .stroke(
                            Color.blue4,
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
                            .system(
                                size: 15,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(
                            Color.blue10
                        )


                    HStack(spacing: 10) {

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
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.blue10)

                        Text(
                            autoOrganize
                            ? "B-Side will find matching Tracks for this collection."
                            : "You'll choose existing B-Side Tracks next."
                        )
                        .font(.system(size: 12))
                        .foregroundStyle(Color.bSideSecondaryText)
                    }
                }
                .tint(Color.bSideBlue)


                // MARK: Create

                Button {

                    createCollection()

                } label: {

                    Text("Create Collection")
                        .font(
                            .system(
                                size: 17,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.white)
                        .frame(
                            maxWidth: .infinity
                        )
                        .frame(height: 56)
                        .background(
                            canCreate
                            ? Color.bSideBlue
                            : Color.blue3
                        )
                        .clipShape(
                            Capsule()
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
