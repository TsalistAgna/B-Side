//
//  HomeView.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI
import Photos

struct HomeView: View {

    @ObservedObject
    var viewModel: HomeViewModel


    private let columns = [

        GridItem(
            .flexible(),
            spacing: 10
        ),

        GridItem(
            .flexible(),
            spacing: 10
        ),

        GridItem(
            .flexible(),
            spacing: 10
        ),

        GridItem(
            .flexible(),
            spacing: 10
        )
    ]


    var body: some View {

        ZStack {

            Color.bSideBackground
                .ignoresSafeArea()


            mainContent
        }
    }


    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {

        if viewModel.isLoading {

            ProgressView(
                "Finding your tracks..."
            )

        } else if viewModel.tracks.isEmpty {

            EmptyHomeView(
                permissionStatus:
                    viewModel.permissionStatus
            ) {

                handleAddScreenshot()
            }

        } else {

            homeContent
        }
    }


    // MARK: - Home Content

    private var homeContent: some View {

        ScrollView(
            showsIndicators: false
        ) {

            VStack(spacing: 24) {


                // MARK: Today's Finding

                if let finding =
                    viewModel.todaysFinding {

                    DailyFindingCard(
                        track: finding
                    )

                } else {

                    waitingForFindingView
                }


                // MARK: Latest Track

                VStack(
                    alignment: .leading,
                    spacing: 14
                ) {

                    Text("Latest Track")
                        .font(
                            .system(
                                size: 22,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(
                            Color.bSideDarkBlue
                        )


                    LazyVGrid(
                        columns: columns,
                        spacing: 10
                    ) {

                        ForEach(
                            viewModel.latestTracks
                        ) { track in

                            TrackThumbnail(
                                track: track
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)

            // Space for floating tab bar
            .padding(.bottom, 110)
        }
    }


    // MARK: - Waiting For AI

    private var waitingForFindingView: some View {

        VStack(spacing: 12) {

            Text("Today’s Track Finding!")
                .font(
                    .system(
                        size: 24,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.bSideDarkBlue
                )


            if viewModel.isAnalyzing {

                ProgressView()

                Text(
                    "B-Side is organizing your tracks..."
                )
                .font(.system(size: 14))
                .foregroundStyle(
                    Color.bSideSecondaryText
                )

            } else {

                Image(
                    systemName: "sparkles"
                )
                .font(
                    .system(size: 34)
                )
                .foregroundStyle(
                    Color.bSideBlue
                )


                Text(
                    "No finding yet."
                )
                .font(.system(size: 14))
                .foregroundStyle(
                    Color.bSideSecondaryText
                )
            }
        }
        .padding(.vertical, 20)
    }


    // MARK: - Add Screenshots

    private func handleAddScreenshot() {

        switch viewModel.permissionStatus {

        case .denied, .restricted:

            openSettings()

        default:

            Task {
                await viewModel.requestPermission()
            }
        }
    }


    // MARK: - Open Settings

    private func openSettings() {

        guard let url = URL(
            string: UIApplication.openSettingsURLString
        )
        else {
            return
        }

        UIApplication.shared.open(url)
    }
}


#Preview {

    HomeView(
        viewModel: HomeViewModel()
    )
}
