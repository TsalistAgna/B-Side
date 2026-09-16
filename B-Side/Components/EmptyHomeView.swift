//
//  EmptyHomeView.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI
import Photos

struct EmptyHomeView: View {

    let permissionStatus: PHAuthorizationStatus

    let onAddScreenshots: () -> Void

    var body: some View {

        VStack(spacing: 18) {

            Spacer()


            Image(systemName: "photo.stack")
                .font(
                    .system(size: 48)
                )
                .foregroundStyle(
                    Color.blue4
                )


            VStack(spacing: 8) {

                Text("No finding yet :(")
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
                    "Add your screenshots to start your first B-Side."
                )
                .font(
                    .system(size: 15)
                )
                .foregroundStyle(
                    Color.bSideSecondaryText
                )
                .multilineTextAlignment(.center)
            }


            PrimaryButton(
                title: buttonTitle
            ) {
                onAddScreenshots()
            }
            .padding(.horizontal, 30)


            Spacer()
        }
    }


    private var buttonTitle: String {

        switch permissionStatus {

        case .denied, .restricted:
            return "Allow Screenshot Access"

        default:
            return "Add Your Screenshots"
        }
    }
}
