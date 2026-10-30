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
                .foregroundStyle(Color.accentForeground)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(minHeight: BSideLayout.buttonMinimumHeight)
                .background(Color.accentPrimary)
                .clipShape(
                    RoundedRectangle(cornerRadius: BSideLayout.buttonMinimumHeight / 2)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PrimaryButton(
        title: "Organize Tracks"
    ) {

    }
    .padding()
}
