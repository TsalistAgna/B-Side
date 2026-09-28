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

    var body: some View {

        ZStack {

            Color.black
                .ignoresSafeArea()


            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 8)


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
                                width: 40,
                                height: 40
                            )
                            .background(
                                Color.black.opacity(0.5)
                            )
                            .clipShape(Circle())
                    }
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
