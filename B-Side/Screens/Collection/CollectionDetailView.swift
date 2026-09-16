//
//  CollectionDetailView.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 16/09/26.
//

import SwiftUI

struct CollectionDetailView: View {

    let category: BSideCategory

    @ObservedObject
    var viewModel: HomeViewModel

    let onBack: () -> Void


    @State
    private var selectedTrack: Track?


    private let columns = [

        GridItem(
            .flexible(),
            spacing: 16
        ),

        GridItem(
            .flexible(),
            spacing: 16
        )
    ]


    private var collectionTracks: [Track] {

        viewModel.tracks(
            in: category
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

                            Button {

                                selectedTrack =
                                    track

                            } label: {

                                TrackCollectionCard(
                                    track: track
                                )
                            }
                            .buttonStyle(.plain)
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
            .presentationCornerRadius(30)
        }
    }


    // MARK: - Header

    private var header: some View {

        ZStack {

            VStack(spacing: 4) {

                Text(category.title)
                    .font(
                        .system(
                            size: 20,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        Color.bSideDarkBlue
                    )


                Text(
                    "\(collectionTracks.count) tracks"
                )
                .font(
                    .system(size: 13)
                )
                .foregroundStyle(
                    Color.bSideSecondaryText
                )
            }


            HStack {

                CircleButton(
                    icon: "chevron.left"
                ) {
                    onBack()
                }


                Spacer()


                CircleButton(
                    icon: "plus"
                ) {

                    Task {
                        await viewModel.loadScreenshots()
                    }
                }
            }
        }
        .frame(height: 58)
    }
}
