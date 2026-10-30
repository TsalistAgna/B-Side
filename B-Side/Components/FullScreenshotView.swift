//
//  FullScreenshotView.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 18/09/26.
//

import SwiftUI

struct FullScreenScreenshotView: View {

    @Environment(\.dismiss)
    private var dismiss

    let image: UIImage
    var accessibilityDescription = "Screenshot"

    var body: some View {

        ZStack {

            Color.black
                .ignoresSafeArea()


            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 8)
                .accessibilityLabel(accessibilityDescription)


            VStack {

                HStack {

                    Spacer()

                    Button {
                        dismiss()
                    } label: {

                        Image(systemName: "xmark")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(.white)
                            .frame(
                                width: BSideLayout.minimumTouchTarget,
                                height: BSideLayout.minimumTouchTarget
                            )
                            .background(
                                Color.black.opacity(0.5)
                            )
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Close full screenshot")
                }

                Spacer()
            }
            .padding(20)
        }
    }
}


#Preview {

    FullScreenScreenshotView(
        image: UIImage(
            systemName: "photo"
        )!
    )
}
