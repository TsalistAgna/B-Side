//
//  PrimaryButton.swift
//  B-Side
//
//  Created by Baiq Annisa Tsalist Agna on 15/09/26.
//

import SwiftUI

struct PrimaryButton: View {

    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.bSideBlue)
                .clipShape(
                    RoundedRectangle(cornerRadius: 26)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PrimaryButton(
        title: "Organize Tracks"
    ) {
        print("Button tapped")
    }
    .padding()
}
