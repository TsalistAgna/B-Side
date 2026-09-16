//
//  CollectionView.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI

struct CollectionView: View {

    @ObservedObject
    var viewModel: HomeViewModel
    
    let onSelectCollection:
            (BSideCollection) -> Void

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


    var body: some View {

        ZStack {

            Color.bSideBackground
                .ignoresSafeArea()


            if viewModel.collections.isEmpty {

                emptyView

            } else {

                collectionContent
            }
        }
    }


    // MARK: - Content

    private var collectionContent: some View {

        ScrollView(
            showsIndicators: false
        ) {

            VStack(spacing: 24) {


                // MARK: Header

                header


                // MARK: Collection Grid

                LazyVGrid(
                    columns: columns,
                    spacing: 16
                ) {

                    ForEach(
                        viewModel.collections
                    ) { collection in

                        Button {

                            onSelectCollection(
                                collection
                            )

                        } label: {

                            BSideCollectionCard(
                                collection:
                                    collection
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 36)

            // Space for floating bottom navigation.
            .padding(.bottom, 120)
        }
    }


    // MARK: - Header

    private var header: some View {

        ZStack {

            Text("B-Side Collection")
                .font(
                    .system(
                        size: 20,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    Color.bSideDarkBlue
                )


            HStack {

                Spacer()


                Button {

                    addCollection()

                } label: {

                    Image(
                        systemName: "plus"
                    )
                    .font(
                        .system(
                            size: 26,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(.white)
                    .frame(
                        width: 42,
                        height: 42
                    )
                    .background(
                        Color.bSideBlue
                    )
                    .clipShape(
                        Circle()
                    )
                }
            }
        }
        .frame(height: 42)
    }


    // MARK: - Empty View

    private var emptyView: some View {

        VStack(spacing: 14) {

            Spacer()


            Image(
                systemName: "opticaldisc"
            )
            .font(
                .system(size: 54)
            )
            .foregroundStyle(
                Color.blue3
            )


            Text("No B-Sides yet")
                .font(
                    .system(
                        size: 24,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    Color.bSideDarkBlue
                )


            Text(
                viewModel.isAnalyzing
                ? "B-Side is organizing your tracks..."
                : "Your organized screenshots will appear here."
            )
            .font(
                .system(size: 15)
            )
            .foregroundStyle(
                Color.bSideSecondaryText
            )
            .multilineTextAlignment(
                .center
            )


            if viewModel.isAnalyzing {

                ProgressView()
                    .padding(.top, 8)
            }


            Spacer()
        }
    }


    // MARK: - Actions

    private func collectionTapped(
        _ collection: BSideCollection
    ) {

        print(
            "Open:",
            collection.category.title
        )
    }


    private func addCollection() {

        print(
            "Create custom B-Side"
        )
    }
}


#Preview {

    CollectionView(
        viewModel:
            HomeViewModel(),
        onSelectCollection: { _ in }
    )
}
